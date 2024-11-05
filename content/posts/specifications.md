---
author: ["Minhaj U. Khan"]
title: "Specifications Pattern"
date: "2024-11-05"
description: "An attempt to explain the specifications pattern from the Domain Driven Design Book"
ShowToc: false
TocOpen: false
---

## Imagine
Your company manages an inventory of lego blocks. 

One fine day, the company gets a requirement to deliver the legos to Switzerland that are

- either red or white
- are of sizes 6x10 or 5x5
- if they are 5x5, they must be taller than 2cm
- if they are 6x10, they must be shorter than 3cm
- not more than 8k in total

You, as a software engineer in the company is tasked write an API that takes in requirements like these, and return lego shelf location so the warehouse can pack and ship.

You write a simple query

```sql
SELECT shelf_location
FROM legos
WHERE (color = 'red' OR color = 'white')
  AND ((size = '6x10' AND height < 2) OR (size = '5x5' AND height > 3)) LIMIT 8000;
```

and then you put that in code.

```go
func (r *repository) GetLegoShelfPositions(
	ctx context.Context,
	firstLegoDimension, secondLegoDimension entities.LegoDimension,
	colors []string,
	limit int,
) ([]string, error) {

	rows, err := r.db.Query(`
		SELECT shelf_position
		FROM legos
		WHERE color = ANY($1) 
		AND ((size = $2 AND height < $3) OR (size = $4 AND height > $5)) LIMIT $6
	`, colors,
		firstLegoDimension.Size,
		firstLegoDimension.Height,
		secondLegoDimension.Size,
		secondLegoDimension.Height,
		limit,
	)

	if err != nil {
		return nil, err
	}

	defer rows.Close()

	positions := make([]string, 0)
	for rows.Next() {
		var shelfPosition string
		if err := rows.Scan(&shelfPosition); err != nil {
			return nil, err
		}
		positions = append(positions, shelfPosition)
	}
	return positions, nil
}

```

## Moment of Reflection

At this point now, you’ve taken a [“business”](https://thecodest.co/dictionary/business-logic-layer/) requirement, and wired them into the [“repository”](https://medium.com/@pererikbergman/repository-design-pattern-e28c0f3e4a30) layer. 

**When faced with situations where you want to query “business objects” that match a certain “criteria” - use the Specifications pattern.**

The specification pattern is asking whether a business object satisfies a set of requirements.

For example, in our case of Legos that need to be shipped to Switzerland:

```go
swissSpecification.IsSatisfiedBy(lego)
```

The implementation is also super simple.

```go
func (s *LegoSpecification) IsSatisfiedBy(lego entities.Lego) bool {
	if !slices.Contains(s.colors, lego.Color) {
		return false
	}

	for _, dimension := range s.dimensions {
		if lego.Dimensions.Equals(dimension) {
			return true
		}
	}
	return false
}
```

At this point, you can also fetch all the legos and filter them through
the specification

OR better yet, move the query, closer to the business specification

```go
func (s *LegoSpecification) AsSQL() (query string, args []any) {
	// Initial part of the query
	args = []any{s.colors} 
	query = "SELECT shelf_position FROM legos WHERE color = ANY($1)"

	// Prepare dynamic conditions for size and height
	dimensionClauses := []string{}
	for _, dimension := range s.dimensions {

		sizeArg := len(args) + 1
		heightArg := len(args) + 2

		// Append condition for each dimension
		dimensionClauses = append(dimensionClauses, fmt.Sprintf("(size = $%d AND height < $%d)", sizeArg, heightArg))

		// Append size and height values to args
		args = append(args, dimension.Size, dimension.Height)
	}

	if len(dimensionClauses) > 0 {
		query += " AND (" + strings.Join(dimensionClauses, " OR ") + ")"
	}

	args = append(args, s.notMoreThan)
	query += fmt.Sprintf(" LIMIT $%d", len(args))
	return query, args
}

```

And finally, you can now simple plug this specification in your “repository” layer.

```go
func (r *repository) GetLogoBySpecification(ctx context.Context, spec Specification[Lego]) ([]string, error) {
	query, args := spec.AsSQL()
	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	positions := make([]string, 0)
	for rows.Next() {
		var shelfPosition string
		if err := rows.Scan(&shelfPosition); err != nil {
			return nil, err
		}
		positions = append(positions, shelfPosition)
	}
	return positions, nil
}
```

Voila! All the business removed from the repository layer.