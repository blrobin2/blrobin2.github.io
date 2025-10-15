---
layout: post
title: "Functional vs. Object-Oriented in JavaScript"
excerpt: "Why must we choose?"
category: programming
---

A (not so) recent trend in JavaScript has been to migrate from some of the object-oriented thinking that has driven a lot of larger projects towards a more functional way of thinking.

I'm not too interested in describing the paradigms in and of themselves. I'll defer you to [Eric Elliot's article on the basics of functional programming](https://medium.com/javascript-scene/master-the-javascript-interview-what-is-functional-programming-7f218c68b3a0), and for object-oriented programming, this [older but more principled primer on object-oriented programming](http://journals.ecs.soton.ac.uk/java/tutorial/java/objects/index.html).

When you look at both of these concepts at their core, you might see them as diametrically opposed to one another. And, if you listened to [Eric Elliot's description of OOP](https://medium.com/javascript-scene/the-two-pillars-of-javascript-ee6f3281e7f3), you might come to the conclusion that object-oriented programming is a "bad thing" that should be avoided. Of course when pressed, [Eric Elliot does not outright dismiss OO](https://medium.com/@_ericelliott/in-my-opinion-functional-and-object-oriented-programming-can-complement-each-other-1a6a5f06d4a7), but some of it's more common patterns. I don't mean to pick on Eric, he's just a readily available example. And on the other side, you have folks like Dr. Axel Rauschmayer who argue that [some concepts in functional programming, such as currying, do not mesh well with the JavaScript ecosystem](http://2ality.com/2017/11/currying-in-js.html).

I will admit that the JavaScript community has not made a strong argument for OOP in a few years. The [best](http://eloquentjavascript.net/06_object.html) [writings](https://addyosmani.com/resources/essentialjsdesignpatterns/book/) on it seem dated when we have [ES6 Classes](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes) that provide sugar for some of these patterns. However, some patterns, such as mixins, are difficult (not impossible). Also, since mixins are not a baked in concept in JavaScript, there's little agreement on what that actually looks like. Still, [the conversation is happening](http://raganwald.com/2015/12/23/super-considered-hmmmful.html) if you dig deep enough. But I digress.

When we look at both paradigms in the context of JavaScript, we can observe the following prescription from both schools: with us, you will gain great power, but at a cost.

In the OOP world, that power is the ability to encapsulate complexity and delegate responsibilities to those containers of completexity, keeping your code losely coupled and highly organized. The cost, however, is the freedom to ignore [SOLID principles](<https://en.wikipedia.org/wiki/SOLID_(object-oriented_design)>) and create deep hierachies, tight coupling, and a lot of state whose values we can barely enforce without a type system. For that last problem, we have options like [TypeScript](https://www.typescriptlang.org/) or [Flow](https://flow.org/) that can assist in the prevention of "a is undefined" type runtime errors by ensuring that code is operating on what it expects.

In the FP world, that power is the ability to compose complex behaviors from basic, stateless functions, building up a side-effect free application that acts only when you want it. The cost, however, is a language that conceptually supports these ideas but must be tightened up with stacks of libraries, such as [Ramda](http://ramdajs.com/), [Sanctuary](https://sanctuary.js.org/), or a pile of ESLint rules. That is, the language does not enforce the constraints that makes functional programming as a full-application concept worthwhile, and must be siloed. To mitigateTo mitigate this, FP langugages like [Elm](http://elm-lang.org/) and [PureScript](http://www.purescript.org/) that compile to JavaScript have come into play.

If I were to sum up these ideas:

- OOP - With great power comes great responsibility
- FP - With great constraint comes great power

I will admit that I have a bias for OOP as we have [decades of lessons in the paradigm](https://martinfowler.com/eaaCatalog/) that can be applied in a JS context without any libraries. In FP, [we absolutely have patterns in concepts like Functors, Applicatives, Monads, etc](http://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html). The issue in JS is that these must be provided by a library or built yourself if you want access to their power.

Some functional concepts have arrived in JS. [Map, reduce, and filter](https://danmartensen.svbtle.com/javascripts-map-reduce-and-filter) allow us more declaritive, functional means of processing collections. And JS has always been functional in the sense that functions are first-class members of the language, and can be passed around as arguments to other functions, allowing higher-order functions to emerge. Using Object.freeze, we can make immutable structures and keep our state management lower.

What I mean to say is this: despite what the internet says, we can absolutely use both in JavaScript. We can ensure that our classes allow little-to-no state change and create new instances for major changes. We can wrap powerful functional libaries in objects and functions, sharing their power in a more loosely coupled way. Outside of the JS ecosystem, [writers are looking at ways to incorporate FP in OOP ecosystems](http://www.jot.fm/issues/issue_2009_09/article5.pdf). If you want interopability and don't mind compiling your JS, you can looking projects like [Scala.js](https://www.scala-js.org/) which blend OOP and FP concepts (like Scala itself). And clearly, I'm not the only one thinking about this. [Here's an article from the brilliant Reginald Braithwaite on FP vs OOP](http://raganwald.com/2013/04/08/functional-vs-OOP.html).

Hopefully, you'll look at the links provided throughout and come to your own conclusions.
