---
author: ["Minhaj U. Khan"]
title: "Cleanly Misaligned"
date: "2024-12-17"
ShowToc: false
TocOpen: false
---


In the last quarter of 2024, I found myself enjoying re-reading the Domain-Driven Design book and was learning from examples how of the code can potentially be structured, and I tried to apply these patterns at work in my own time and moved things around a bit. It was both, a fun exercise and, a learning experience for me -- and the code was becoming more and more by the book.

A state of flow was achieved and a series of commits followed. Even though I added the reasoning and references from the book in the commit descriptions, I realized later on that it wasn’t enough to take everyone to the same level of understanding.

I falsely assumed that everyone would agree to these refactoring — given the fact that the knowledge was coming directly from the DDD book, but, to my surprise, the outcome was entirely different. I heard feedback that the code is becoming harder to reason with and now has many unnecessary layers around. Things are harder to change. 

Even though the intention behind the refactoring was rooted in cleaner design and doing things by the book, I learnt that my team was forming a different opinion: the code is not easy or familiar to them anymore given the magnitude of changes it has gone through.

I was a bit ignorant of the fact that not everyone is on the same level of experience within the team, and it might be difficult for them to understand the benefits behind the refactoring of one layer to be split into multiple. Not only that, there is now a learning curve for them to decide what goes where in the rather split and structured code that has made its way unexplained to the main branch.

Talking to my manager about the situation, I was advised to talk to the team openly about it. I set up a meeting with everyone and explained how the structure is, what goes where and how should you think about the different building blocks as suggested by the book. I was open to the idea and put it on the table to decide whether the direction in which we were heading is favourable for everyone. If this DDD thing isn’t working for us, then it’s not working for us, and we can pivot. After discussing the situation at length, we finally decided in favour of it, to get familiar with it, and let it sink in — and if it still does more harm than good, we agreed to drop it.

I know that doing things by the book and constantly learning and experimenting are good traits of a Software Engineer, but I learnt that taking juniors on the same journey as you and establishing consensus on things that everyone share — take precedence over tidiness, in most cases.