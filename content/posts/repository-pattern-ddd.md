---
author: ["Minhaj U. Khan"]
title: "DDD Repositories and Transactions"
date: "2024-11-29"
description: "Lessons learnt from writing repositories the non DDD way"
ShowToc: false
TocOpen: true
cover:
    image: "/julian-rojas-dattwyler-LppAkC7s6u4-unsplash.jpg"
---


Let’s say you’re ordering a pizza online and  you get to select the toppings for your pizza. To store this information, the website uses two database tables: pizzas and toppings. 

The [repositories](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-design) to store these can be imagined like this:

```go
pizzaRepository.CreatePizza(ctx, pizza)
toppingsRepository.CreateToppings(ctx, pizza.ID, toppings)
```

Theres a catch when you make the order: if the above two operations don’t happen in a transaction, and the latter fails, you can expect the pizza to be delivered — without toppings. 🧑‍🍳

To fix this, a database transaction needs to be created and shared between the two repositories. 

A transaction can begin and be passed on to these repositories, and then finally commit or rollback given what happens to the operation.

```go
txn := s.transactionsFactory.Begin()
pizzaRepository = s.pizzaRepository.WithTx(ctx, txn)
toppingsRepository = s.toppingsRepository.WithTx(ctx, txn)

pizzaRepository.CreatePizza(ctx, pizza)
toppingsRepository.CreateToppings(ctx, pizza.ID, toppings)

txn.Commit()
```

All looks well and good, and it works. But *(there is always a but),* there are some design issue that come with it.

## Mocks

Lets talk about the tests.

In order to test this piece of code, you need to mock the following:

1. the transaction factory
2. the transaction that the factory builds

Adding a lot of boilerplate code to the tests can become annoying too quickly. 

```go
txn := mocks.NewTransaction()
transactionFactory := mocks.NewTransactionFactory()
pizzaRepository := mocks.NewPizzaRepository()
toppingsRepository := mocks.NewToppingsRepository()

transactionFactory.EXPECT().Begin(any, any).Return(txn)
pizzaRepository.EXPECT().WithTx(any, tx).Return(pizzaRepository)
toppingsRepository.EXPECT().WithTx(any, tx).Return(toppingsRepository)
```

Notice that all the code above does not test the actual business logic, rather just to mock a technical detail.

If you notice, theres a mock, that returns a mock on L6 - *thaaaaat* doesn’t sound very good.

## Dependency Injections

Lets try to imaging what the constructor for the code looks like:

```go
func NewPizzaOrderService(
	transactionFactory transactions.Factory,
	pizzaRepository repository.PizzaRepository,
	toppingsRepository repository.ToppingsRepository,
) Service {}
```

as more dependencies go into the pizza ordering service, the constructor gets fatter. Your linter may start to hint that growing number of arguments aren’t nice. 

> *If your function takes eleven parameters, you probably have forgotten one more.*
> 

## Going against the Guidelines

> *Be conservative in what you do, be liberal in what you accept from others - Jon Postel*
> 

The principle is also known as **Postel's law**, after [Jon Postel](https://en.wikipedia.org/wiki/Jon_Postel), who used the wording in an early specification of [TCP](https://en.wikipedia.org/wiki/Transmission_Control_Protocol)[[1]](https://en.wikipedia.org/wiki/Robustness_principle#cite_note-1). This same principle is also mentioned in the book [100 Go Mistakes and How to Avoid Them](https://www.oreilly.com/library/view/100-go-mistakes/9781617299599/) by Teiva Harsanyi.

By this principle, we should be accepting abstractions *(interfaces)* and returning concrete implementations *(structs)*

Back to our example:

```go
package repository

type PizzaRepository interface {
	WithTx(ctx context.Context, tx ExecutorTx) PizzaRepository
}

func NewPizzaRepository() PizzaRepository { ... }
```

To make this testable, the function’s return type has to be an abstraction (`interface` ) so that it can be mocked. If the function returns a concrete implementation, the mocks would fail because the return type expects to be a `*Repository` but is a `*MockRepository`

## Transactions outside Repositories

Repositories hide infrastructure detail. A database transaction is the implementation detail that a repository should abstract. Say the database was not an SQL database with two tables, but a collection in a NoSQL database where pizza and toppings live in the same document. In that scenario, the service creating and passing the transactions aren't valid anymore. 

The service creating database transaction hinted for bad design.

---

## What went wrong?

***Repositories should not reflect the underlying database tables, but serve a way to interact with domain models.*** 

The problem with our design is that we mapped a repository per database table. 

We shouldn’t ask the repository to create a pizza row and create its pizza toppings rows, rather, we should ask the repository to save a pizza when its orderred. 

A pizza order can contain the pizza and its toppings together — this is called an [aggregate](https://martinfowler.com/bliki/DDD_Aggregate.html) in the DDD world. Martin Fowler puts it in a simple words:

> *A DDD aggregate is a cluster of domain objects that can be treated as a single unit. An example may be an order and its line-items, these will be separate objects, but it's useful to treat the order (together with its line items) as a single aggregate.*
> 

```go
repository.SavePizzaOrder(ctx context.Context, pizzaOrder)
```

Changing the way we think of the repository from *tables* to *domain models* fixes everything. 

- The extra mocks are gone because there is no transaction factory anymore. All the code related to transactions are now part of the repository — which makes perfect sense as it encapsulates the lower level SQL details away from the service.

```go
r := mocks.NewPizzaRepository()
r.EXPECT().SavePizzaOrder(any, any).Return(nil)
```

- Lesser dependency injections to the service is now a reality, no more repositories and transaction factories as dependencies, rather a clean single repository.

```go
func NewPizzaOrderService(r repository.Repository) { ... }
```

- We make Jon Postel happy and play by the book, by being conservative in what we do and liberal in what we expect.

```go
func NewRepository(db ExecutorTx) *Repository { ... }
```

"Simplicity is the ultimate sophistication." — Leonardo da Vinci


### Useful links:

- [Design the infrastructure persistence layer](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-design)

- [Martin Fowler - Aggregates](https://martinfowler.com/bliki/DDD_Aggregate.html)

- [Transactions in Repository Layer](https://www.reddit.com/r/golang/comments/xe2zk4/transactions_in_repository_layer/)