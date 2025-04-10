---
author: ["Minhaj U. Khan"]
title: "Afterthoughts - The Myths about Testing"
date: "2024-11-23"
description: "My after thoughts on the wonderful talk on Testing at Google Devfest 2024 by Danny Preussler from Soundcloud"
ShowToc: true
TocOpen: true
tags: ["Testing"]

---


{{< figure src="/1732379541081.jpeg#center" caption="" width="100%" >}}



- Write tests that help refactoring
- Test behavior not structure
- Reduce writing mocks

I attended a talk from Danny Preussler from Soundcloud in Google DevFest about Testing and the above mentioned were a few key takeaways for me. 

I don’t know whether religiously following test-driven development (I myself do it at work) or just writing tests for the application/service layer is enough. I will not try to advocate what is best, but I would want to share how I feel about the topic.

What I resonated with me the most, was the idea of **having tests that are focused on the behavior, rather than the structure of the code**. To put in more concrete terms, when you have a layered architecture [^1] , changing a very small thing, like a string to an object, may start to break the 7 - 8 test cases you’ve written in each layer. While changing the code maybe very simple, fixing all the broken tests in each layer is cumbersome and time-consuming.

One other thing that hit home was the idea of having lesser mocks. Lesser mocks, means less dependency injections if and only if they are injected for the sole purpose of making something testable.

At the end of the day, having each component fully unit tested does not mean that they working. You have to wire them all together and test whether they work in cohesion or not. 

> Every single test in your test suite is additional baggage and doesn't come for free. Writing and maintaining tests takes time. Reading and understanding other people's test takes time. And of course, running tests takes time.
- Martin Fowler (https://martinfowler.com/articles/practical-test-pyramid.html)
> 

[^1]: The layers can be imagined as application layer, business/domain layer and the repository layer.
