---
layout: post
title: "Heroku/Foreman Environment Variables and Rails"
excerpt: "It's easier than I thought"
category: programming
---

### The Gist

When working with Ruby on Rails, I've usually used [figaro](https://github.com/laserlemon/figaro) or some equivalent gem for handling local environment variables. Recently, I learned that, if I'm planning on deploying to Heroku and I use [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) or [foreman](https://github.com/ddollar/foreman) locally, I don't need to do that

In fact, all I need to do is add a `.env` file in the root of the directory with my environment variables defined. Then, when I start up `foreman`, it will automatically load that `.env` file!

Now, you'll still need to set those environment variables in your deployment environment using [Config Vars](https://devcenter.heroku.com/articles/config-vars), but this makes managing them locally a lot easier, in my opinion

### Example Use Case

In order to give you a solid view on what I mean, I'll provide an example scenario. When using foreman, you may want to throw a debugger line somewhere in your code (using [byebug](https://github.com/deivid-rodriguez/byebug), [pry](https://github.com/pry/pry) or whichever debugger you prefer. For this example, I'll use byebug since it's the default in Rails).

If you want to debug and step through your code from the command line, you cannot simply put a `byebug` statement in your code and load the page. You'll get the code to hault execution, but you will not be able to interact with it. That is because the application is not running on the same thread as your console environment, so all you can do is read from that console

Therefore, you will need to start up a [byebug server](https://github.com/deivid-rodriguez/byebug/blob/master/GUIDE.md#debugging-remote-programs) in a seprate console window in order to interact with byebug

The easiest way to do this (in my opinion) is to add a conditional block to a `byebug` initializer, such as the following:

```ruby
# config/initializers/byebug.rb

if Rails.env.development? && ENV['BYEBUGPORT']
  require 'byebug/core'
  Byebug.start_server 'localhost', ENV['BYEBUGPORT'].to_i
end
```

By allowing the port to be set manually, we:
* Know the port when we pass it
* Avoid port collisions

Now, in the `.env` file, add:

```Environment Variables
// .env
BYEBUGPORT=3001
```

In one console, run:
```bash
byebug -R localhost:3001
```

And in another, run:
```bash
heroku local -f Procfile.dev
```

or:
```bash
foreman start -f Procfile.dev
```

In the browser, load the page that will trigger the `byebug` breakpoint. In the console where you ran the `Procfile`, you should see that the `byebug` breakpoint triggered. In the one where you ran the `byebug` server, you should see the interactive console

### Conclusion

I know this was short and simple, but hopefully it helps someone else who has made this harder on themselves than it had to be

### References

* [Foreman: Use different Procfile in development and production](https://stackoverflow.com/questions/11592798/foreman-use-different-procfile-in-development-and-production)
* [Debugging Rails Applications: Debugging with the `byebug` gem](https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-byebug-gem)
* [Remote Debugging with Byebug, Rails, and Pow](https://www.honeybadger.io/blog/remote-debugging-with-byebug-rails-and-pow/)
* [How to use Byebug with a remote process](https://stackoverflow.com/questions/22794176/how-to-use-byebug-with-a-remote-process-e-g-pow/25823241#25823241)