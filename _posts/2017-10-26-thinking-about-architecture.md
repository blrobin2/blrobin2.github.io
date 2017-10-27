---
layout: post
title: "Thinking About Architecture"
excerpt: "Rambling about architecture"
category: programming
---
## Intro

I've spent hours, days, weeks reading about architecture, looking for good conventions. That doesn't make me any sort of expert, it just means I've read a bunch. This is my trying to get some of the ideas I like out and in concrete forms.

If you spend any time Googling framework Express, you'll inevitably come across questions of code structure. What sort of folder structure should I use to store my code. And, as you'll probably see, the answer can depend on the person or to who the person references. Basically, it depends.

A lot of times, when people ask these questions of code structure, they're not necessarily concerned with "where each file lives" so much as "what files should exist". Not, "how do I keep my code organized", but "how do I structure my application". These are questions of architecture.

Despite what the new and exciting framework people might say, there are conventions and ideas that exist that can be applied to applications of sufficient complexity. Some people hate these conventions and attempt to create new ones. Given enough time, these structures do not differentiate themselves as cleanly from their predecessors as they might believe.

## Obvious exceptions

That isn't to say that no one is adhering to these conventions. You'll find frameworks like Laravel or Nest that utilize these conventions to their benefit, making their code bases easily scale.

And it should also be noted that a lot these established conventions are for backends. What often goes unsaid is that the majority of your application's logic should probably live in a backend.

If you write a React application, your concerns within React should be with getting the data given into the view, and sending the actions performed back to the server. You can validate your data either way, if you wish, on the client side. But if these validations are sufficiently complex, wouldn't it stand to reason that you would want them to live in the one place you data is going? For example, if you write a web client and perform all of your validations there, then need to make an iOS or Android client, you'll need to duplicate all of that logic again.

That isn't to say you shouldn't perform ANY validation on the client. Checking for presence or general types might prevent a trip to the server and save you on resources. But for questions of business logic, things that pertain to how the business operates and what it determines is "valid" data, this should live on the server.

Those exceptions aside, here's some thoughts.

* [Laravel](https://laravel.com/)
* [Express](http://expressjs.com/)
* [React](https://reactjs.org/)
* [Nest](https://docs.nestjs.com/)
* [Ruby on Rails](http://rubyonrails.org/)

# HTTP Verbs

For any API, you're going to have URLs that are the entry points into the application. You'll have:

* GETs for reading resources
* POSTs for creating new resources
* PUTs for completely replacing a resource
* PATCHES for partial modifying a resource
* DELETE for deleting a resources

There's also HEAD, CONNECT, OPTIONS, TRACE, and maybe some others. I've seen HEAD used, but rarely. HEAD is the same as making a GET request, but only grabs the header data. That said, If you understand the five listed verbs, you're ahead of most of Stack Overflow and the majority of APIs written.

I don't think many servers support PATCH, so if you use it, it might just map to a POST under the surface. The main difference to note between POST and PUT is that POST should be expected to do a new write every time it's called, whereas PUT is expected to be "idempotent": that is, it should have no side effects, and has the same effect on the server if called once or called multiple times.

For example, if I have a user and I'm updating their email address, a PUT would replace that user once with a user with the same data and the updated email. If I made the same request, it would not make any additional change. It may still replace the existing user with a new user with the updated email, but since we've already done that, it has the appearance of having done nothing.

Of the main five verbs, only GET is considered "safe". Safe means that it has no effect on the server. It's just a query. This means that it's also "cacheable", meaning the data fetched can be stored away and used for subsequent requests instead of hitting the server again. This depends, though, on how often your data changes. If it changes regularly &mdash; such as a support ticket &mdash; then caching will potentially provide stale data to the client.

* [MDN Article on HTTP request methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)

## Services

If the application is trivial and you don't expect it to grow bigger than a call or two, you can probably get away with keeping all of your logic close to the requests coming in. In Express, this ends up being a callback. In Nest, this ends up being inside the controller for the given route.

If you end up doing repeatable bits of behavior, you may want to extract some of that logic and store it away in a service function or class. For example, say you need to be able to work with user data in multiple domains, say, posts and profiles. Directly accessing that data from a database or NoSQL solution in each request likely ends up with repeated bits of code. All this means is that you have the overhead of accessing that database stored away in the service, so you can just pull in the service to make your calls instead of doing it directly. If you write it as a function, you'll want to also return some way of disconnecting from the database if making multiple calls, or handle it directly in the function.

This will service a large amount of applications. I know it's not cool and exciting, but keeping your sections of code small and composable is the goal here, not building the best possible structure.

## Middleware

So, where is the line? I think the first place is when you have to introduce middlewares. If you're not familiar, middlewares are just functionality that sits between the client request and the code meant to handle that request. Some uses for middleware:

* validating a request to ensure the request is allowed to have it.
* decorating a request with a token if the request needs it to do any additional work.
* logging the incoming request and monitor it.
* caching data

Express and Nest both provide a simple way to define middlewares by defining a function that takes in an expected set of parameters, doing the work you'd like to do, and then calling the passed in next() to either trigger the next middleware in the stack or to go on to your request.

Keeping these middlewares in separate files and importing them where needed is a nice way to keep your code loosely coupled and reduce the cognitive overhead of trying to read your top level application file that ties it all together.

* [Middleware: THE core of node.js backend apps](https://hackernoon.com/middleware-the-core-of-node-js-apps-ab01fee39200)
* [Using middleware in Express](http://expressjs.com/en/guide/using-middleware.html)

## Models and ORMs

Sometimes, you need to know more about the types of data you're working with in the backend. You need to more clearly represent the relationships between elements in your application and how they relate to one another. This is when I like to introduce models.

If you're familiar with the MVC (Model-View-Contoller) pattern, you may believe that the model is a single object that holds all the information about your nouns. So for your users, you have a User object, with all the accessors and mutators. If you've used Laravel or Ruby or Rails, then you might be familiar with Active Record ORMs, where you model extends a base class that provides all sorts of methods for saving and retrieving data.

In this stage, I'd say, if all you are doing are basic CRUD operations (Create-Read-Update-Delete) on the database, an Active Record implementation would probably make your life easier and get the job done. The only reason I didn't recommend this for a smaller project is that, while it is nice and helpful, it's also a library that increases the size of your application, and it's another 3rd-party library your code is depending on. Basically, it can be overkill.

One of the big differences is that, with Active Record, all your searching and saving is done through the Model object. With Data Mapper, your Model is just a basic class, perhaps with some annotations for types, called an Entity. You don't do your saving and accessing on the Entity itself, but through a Repository. That it's sole responsibility, taking care of persisting your Entities. Therefore, your Model becomes the pairing of the Entity and the Repository. Refer to the article on ORMs and Anemic Domain Models (linked below) for more information

I'll just say I'm a big fan of , in part, because it provides Active Record AND Data Mapper implementations. It does, however, rely on TypeScript. You're probably better off using something like Sequelize, which is more popular and supports both JavaScript and TypeScript.

* [Active Record](https://www.martinfowler.com/eaaCatalog/activeRecord.html)
* [Data Mapper](https://martinfowler.com/eaaCatalog/dataMapper.html)
* [ORMs and Anemic Domain Models](http://fideloper.com/how-we-code)
* [TypeORM](https://github.com/typeorm/typeorm)
* [Sequelize](http://docs.sequelizejs.com/)

## Example

So, for me, if I'm concerned with the architecture of my application, I'll have incoming requests routed to a Controller method. That method invokes a call to the necessary services to handle that request. Each Service can range in depth, depending on how complex the domain is. That is, how much knowledge and how many actions pertaining to that knowledge does the application have to maintain.

By deferring logic in Controllers to a Service, I have a consistent barrier type into my code, and that service layer can be expanded out as deeply as I need it to be.

That should also be noted: your architecture won't ever be a one size fits all, even with a single application. You should try for the simplest representation of your logic first. But as it grows in complexity, you should be breaking your code down. I'll provide more examples as we go.

The Service will most often hand off it's call to the Repository, which will take care of fetching and persisting the Entities, based on what action the call is making.

Depending on how your repositories are set up, you may also have services for things like the database, providing a clean way to access a db connection without passing around credentials or config, or for a 3rd-party messaging service such as Redis or RabbitMQ. Some frameworks have the notion of providers for this sort of thing, but no need to marry their terminology unless you're adopting it wholesale. The important thing is to have a way of breaking down your application by its concerns and keeping yourself sane as your application grows.

If you use something like Laravel or Ruby on Rails, your code will probably be some version of this, maybe simpler. For the vast majority of applications written on the internet, this is "Good Enough". Like I said, not terribly exciting, but it provides clear boundaries between concerns, which makes expanding easier.

You're not committing to one structure here. You're making smart choices that aren't over architected that allow your architecure to grow as it's needed.

* [Redis](https://redis.io/)
* [RabbitMQ](https://www.rabbitmq.com/)

## Events

Sometimes, your domain is so complex that the behaviors that you need to represent can't be mapped to simply updating a database. Yes, in the end you're still writing to a database. But maybe you're also sending off emails. Maybe you have several other microservices that need to sync up with the actions that take place in your applications, and they need to know more than just a column was updated. Maybe you need to kick of a resource-intensive algorithm based on incoming data to run in the background and improve user recommendations.

And maybe you don't. And that's okay. I say it over and over, because I ignored so much advice when I worked on smaller applications to keep it simple. I wanted to make my stack more complex, because I thought it was "better". And all I did was invest in a ton of extra work for very little return.

But if you do, you might want a more event-oriented architecture. The same way as in the DOM we have event listeners for user interactions, we sometimes want event listeners for certain actions taken in the application.

For example, say you have an inventory system. Someone has checked out a certain number of items. You could represent this as "subtract that amount from the quantity column". And that could be enough. But what if, when a certain number of items are checked out, we need to issue a reorder of that item. Or we need to notify a member of the team an an unnusual amount of an item was checked out. Or we need to keep a log of every check in and check out that occurs. These are Events.

In an application with Events, you have the Events that are fired, and the Listeners who respond to those Events. Those Listeners can fire off other Events, interact with 3rd-party services, whatever it needs to do. The same logic applies of keeping your resources isolated and using them where needed. You don't want your Events holding your business rules, you only want them to fire off actions.

So, in our inventory example, where would the check live, if not in the Event itself? It would live on the Entity. You would have a method like `itemNeedsToBeReordered` or `inventoryNeedsRefill` (the name here should reflect the language used by the people who use your application, the language of the business), which contains the rules for when an item needs to be reordered and returns a boolean. If it's true, we might have another method for `amountToReorder` on the Entity that knows how much to reorder when needed. The idea is less "this is how to do it", but more, "the logic lives in the model".

Then, whenever inventory is updated, you'd kick off an event `InventoryUpdated`, which asks an ItemService to check the inventory logic, and if something needs to be done, fires off some OrderingService, or whatever it is, asking the Model for how much to order. Each domain knows just what it needs to, and talks to each other through their services.

There's a classic habit that regularly occurs in applications with services is to give the services all the power and all the knowledge. That's not the purpose of services. They're just means of crossing bounded contexts without bringing over the entire domain. They're a thin layer of communications so that each part of the domain doesn't deeply rely on each other to accomplish actions. That way, when a domain does change, it doesn't affect the rest of the application. At most, the service call's underlying code changes. But as far as the other domain is concerned, it can still access the actions it needs.

How the pairing of Events and Listeners look depend on your context. They could be functions or they could be full-fledged classes. The important thing is isolation of concerns.

* [Observer Pattern](https://addyosmani.com/resources/essentialjsdesignpatterns/book/#observerpatternjavascript)
* [NodeJS Events](https://nodejs.org/api/events.html)
* [Laravel Events](https://laravel.com/docs/5.2/events)

## More to come

I've got more on my mind about enterprise-grade application architecture, but I'll stop here for now. I've tried to link to relevant resources throughout that's probably clearer than any of my ramblings thus far. But for anyone who stumbles accross this article: if nothing else, I hope this points you in an helpful direction.