---
layout: post
title: "Go Lang: Stockholm Syndrome or Fear of Magic?"
excerpt: "Why do people love GoLang? I genuinely don't get it"
category: programming
---

After some major changes at my current job, the majority of code I will be writing for the forseeable future will be in [Go](https://golang.org/). Prior to this, many projects were written in the programming language best suited to the team supporting it, so we have tools written in PHP, Ruby, Java, Python... It's understandable why they would want to unify around a single language.

What I don't get is why they chose Go.

Actually, let me be up front, I know exactly why they chose Go.

## Why Teams Choose Go

1. It's "Fast"

One of the most replicated arguments for choosing Go is it's speed. That is, how fast the applications run once they are compiled. Unlike dynamic languages like PHP and Ruby, or languages with Runtime VMs like Java, Go is compiled to machine language, which in theory should make it outperform those languages.

However, unlike other languages that compile to machine language (C, C++, Rust), Go has a [garbage collector](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) for memory management. Because of this, your Go code will actually only be as fast as your allocated memory will allow in any given block. This means that it is still up to you to wisely choose when to utilize pointers, when to pass values around, when to close leaky resouces, and so on.

That said, Go applications will still likely outperform most PHP and Ruby applications. More on this later.

1. It's Small

Another common argument for choosing Go is the size of the language itself. That is, how many unique symbols and language constructs you need to learn in order to utilize the language. Modeling itself after a terser C++, you essentially have some primitives, a struct, an interface, one looping construct, goroutines, and defers. I invite you to check out the [Tour of Go](https://tour.golang.org/welcome/1) to see how little there is to the language.

From a company onboarding standpoint, it makes a lot of sense to choose a language that doesn't take long to learn. When looking for viable candidates, Go is still not as popular as the other languages mentioned, so the likelihood of finding a seasoned Go developer is still small, depending on your market.

From a developer standpoint, you may find some tasks much easier than in C or C++, but others quite verbose. Because there is so little to the language, you lose a number of conveniences that you may have grown accustomed to, such as native sorting, generic collections, and so on.

If you are transitioning from a language like Node.js or C, you will probably not feel these pain points quite so much. Again, more on this later.

1. It's Consistent

The final argument I will mention here is that, because the language has standardized documentation, formatting, and testing, the code you will come across in many packages will largely look the same.

This is quite nice all around, as it means that you will quickly be able to pick up on common patterns and confidently replicate them in your own code without having to worry if there is a "better" or "more efficent" way of doing things.

However, that question of "better" or "more efficient" may not go away, as though it doesn't exist, you might want it.

## Why I Wouldn't Choose Go

1. It's not fast enough

I know, I said above that it is fast. But I also said that it is contingent on application size. If you pull in a number of libraries (which you will to save yourself some typing) and you glue them together (which you will have to, because many of these libraries do not talk to each other), you might find your throughput plummit.

I can speak from personal experience that any given API developed using the stack our team has chosen averages around 3-20 seconds per request. That is insane.