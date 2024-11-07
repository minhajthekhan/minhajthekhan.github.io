---
author: ["Minhaj U. Khan"]
title: "Specifications  📄"
date: "2024-11-07"
description: "A story of shipping lego blocks to Switzerland"
ShowToc: false
TocOpen: false
cover:
    image: "https://cdn.britannica.com/48/182648-050-6C20C6AB/LEGO-bricks.jpg"
---

Your company manages an inventory of lego blocks. 

One fine day, the company gets a requirement to deliver the legos to Switzerland that are

- Either red or white.
- Are of sizes 6x10 or 5x5.
- If they are 5x5, they must be taller than 2cm.
- If they are 6x10, they must be shorter than 3cm.
- Not more than 8k in total.

You, as a software engineer in the company is tasked write an API that takes in these requirements, 
and outputs the lego's **shelf location**
so the warehouse can pack and ship.

You write a simple query

```sql
SELECT shelf_location
FROM legos
WHERE (color = 'red' OR color = 'white')
  AND ((size = '6x10' AND height < 2) OR (size = '5x5' AND height > 3)) LIMIT 8000;
```

and then you put that in code.

```go
func (r *repository) GetLegoShelfPositions(ctx context.Context, d1, d2 LegoDimension, colors []string, limit int) ([]string, error) {
	args := []any{colors, d1.Size, d1.Height, d2.Height, d2.Size, limit}
	rows, err := r.db.Query(`
		SELECT shelf_position
		FROM legos
		WHERE color = ANY($1) 
		AND ((size = $2 AND height < $3) OR (size = $4 AND height > $5)) LIMIT $6
	`, args...)
	if err != nil {
		return nil, err
	}

	defer rows.Close()
	return r.scanRowsAndGetPositions(rows)
}
```

## Moment of Reflection

Imagine you get another draft of the requirement and some amends have been made. To make those changes, you need to open
up this repository function and make changes to the query. Each time the requirement changes, your repository function needs to be modified.

At this point, you’ve taken the "business" requirements and translated them into a "repository" function in a query.

### Enter Specifications Pattern

A nice piece on where the specifications pattern helps from [Martin Fowler](https://www.martinfowler.com/apsupp/spec.pdf):

> You need to select a subset of objects based on some criteria, and to refresh the selection at various times
> 

For example, in our case of Legos that need to be shipped to Switzerland:
```go
swissSpecification.IsSatisfiedBy(lego)
```

Implementing the specificiation directly from the requirements:

```go

type LegoSpecification struct {
	colors      []string
	dimensions  []LegoDimension
	notMoreThan int
}

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

We can also now add an API on top of the `Specification`
so that the repository can use it to _select a subset of objects based on given criteria._

```go
func (s *LegoSpecification) AsSQL() (query string, args []any) {
	args = []any{}
	query = "SELECT shelf_position FROM legos"

	query, args = s.buildColorQuery(query, args)
	query, args = s.buildDimensionsQuery(query, args)
	query, args = s.buildNotMoreThanQuery(query, args)
	return query, args
}
```

Finally,
wiring it up 

```go
func (r *repository) GetLogoBySpecification(ctx context.Context, spec Specification[Lego]) ([]string, error) {
	query, args := spec.AsSQL()
	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}

	defer rows.Close()
	return r.scanRowsAndGetPositions(rows)
}
```


You can look at the complete code [here](https://github.com/minhajthekhan/scratchpad/blob/main/specifications/example/pkg/legos/lego.go). 

Happy Coding!

![gif](https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExaHZ3Y250bm05ODgwZWM5N2M2eG5kM3lkZW9jcmY5ejZqcW92MnltcSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/o0vwzuFwCGAFO/giphy.gif#center)