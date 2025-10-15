---
layout: post
title: "My React and Rails Setup"
excerpt: "A very particular setup, and how to go about it"
category: programming
---

### Dude, Why?

There are literally dozens, if not hundreds, of articles like this. But I always find that there is some missing idea or piece that I would like to see but isn't addressed

I'm not going to talk about building any particular app. I'm going to assume that you have done the research and looked at the use cases that your app will have, and you have come to the conclusion that React as your frontend and Rails as an API-only backend will serve your application

I say this because most of the time (seriously, like 90% of the time), this type of setup is too complicated. If you use Rails, and most of your views are CRUD operations, you should probably stick to [Rails views](https://guides.rubyonrails.org/action_view_overview.html). If you do need a bit of dynamic flair (toggling visibility, conditionally required fields, etc), then consider [React on Rails](https://github.com/shakacode/react_on_rails) which still allows you to utilize Rails views while also server-rendering React components when needed

So, what is the use-case where I am going to interact with Rails and React separately? Primarily, enterprise where you have different teams working on different layers of the stack, even different teams working on different components within the app. You need the ability to split out complex parts of your application into separate services so that parts of your API can be used by other teams, but still retain some autonomy

Or, you're trying to prove something and you're not going to let logic get in your way

One more detail: I'm going to setup deployment to [Heroku](https://heroku.com/) because it makes scaling any Rails app super easy. You can even get some flexibility from [deploying using Docker](https://devcenter.heroku.com/categories/deploying-with-docker), but I won't be covering that here

Regardless, let's get started

### Rails API Setup

First, let's generate our new Rails app:

```bash
rails new app_name --api --database postgresql --skip-spring --skip-sprockets --skip-test --skip-action-mailbox
```

- `--api` - we don't want to install all of the view-related stuff
- `--database postgresql` - Feel free to replace with your preferred database vendor, I'm just partial to posgresql
- `--skip-spring` - Rails already comes with Bootsnap, Spring has weird caching issues that can be a pain to solve
- `--skip-sprockets` - I'm pretty sure Rails doesn't install Sprockets with the `api` flag, but it can cause massive issues in this setup so I just want to make sure
- `--skip-test` - I prefer [RSpec](https://rspec.info/) to [the default test framework](https://guides.rubyonrails.org/testing.html), but they're fairly comparable in terms of functionality, so again, I leave this to personal preference
- `--skip-action-mailbox` - If you need to send emails, consider removing this flag. Or try [MailChimp](https://mailchimp.com/) or some other Email SAAS

#### Git Init

Next, I'm going to get my Git setup, including renaming the 'master' branch:

```bash
git init
git add -A
git commit -m "Rails generated code"
git branch -m master main
```

See "Additional Resources" below for motivation

#### ~~Component Init~~ (Never mind)

Initially, I was going to go down the [Rails Components](https://cbra.info/) route, but the amount of setup was enough that I was essentially re-writing the book. It's a great idea for scalability, but for the sake of this article, it's overkill. Check out the book if interested

#### Gems Init

The first thing I like to do with is to clean out all of the comments in my `Gemfile`. This makes it so that Rubocop can alphabetize the gems. Of the commented out gem recommendations, the only one I'm committing to for now is `rack-cors`, so go ahead and ucomment that

As for the rest of the Gems, I'll just show you my `Gemfile` and discuss the ones that require further setup/discussion. If you see a Gem you don't care about, or actively dislike (`annotate` tends to be pretty divisive), feel free to leave it out

We may add more as we go, but this is a good set of defaults:

```ruby
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'bootsnap', '>= 1.4.2', require: false
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 4.1'
gem 'rack-cors'
gem 'rails', '~> 6.0.3', '>= 6.0.3.4'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
end

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'brakeman', require: false
  gem 'bullet'
  gem 'bundler-audit', require: false
  gem 'listen', '~> 3.2'
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end
```

##### Bullet

ActiveRecord queries can be hard to tweak from a performance perspective. Sometimes, there are obvious improvements that you don't notice at the time. [Bullet](https://github.com/flyerhzm/bullet) helps there. As far as config, I generally do (in `config/development.rb`):

```ruby
  config.after_initialize do
    Bullet.enable = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
```

##### RSpec

Since we didn't install the default testing framework, setting up RSpec is super easy, just run:

```bash
bundle exec rails generate rspec:install
```

And it'll generate our `spec` folder and test helpers

Because I use Rails generators for some things, I don't want RSpec generating too much for me (especially since I'm in an API-only environment, so I'll add the following to the `Application` class definition in `config/application.rb`):

```ruby
config.generators do |gen|
  gen.test_framework :rspec,
    fixtures:         false,
    view_specs:       false,
    helper_specs:     false,
    routing_specs:    false,
    request_specs:    false,
    controller_specs: false
end
```

##### Overcommit

[Overcommit](https://github.com/sds/overcommit) is just an easy way to add Git hooks to a Ruby project. It's just an easy way to catch mistakes before doing a commit or push. Here's the config I use (found in `.overcommit.yml`):

```yaml
CommitMsg:
  HardTabs:
    enabled: true

PreCommit:
  BundleAudit:
    enabled: true
    flags: ["--update"]
    on_warn: fail
    command: ["bundle", "exec", "bundle-audit"]

  BundleCheck:
    enabled: true

  RuboCop:
    enabled: true
    on_warn: fail
    command: ["bundle", "exec", "rubocop"]

  RailsSchemaUpToDate:
    enabled: true

  TrailingWhitespace:
    enabled: true
    exclude:
      - "**/db/structure.sql"

  HardTabs:
    enabled: true

PrePush:
  Brakeman:
    enabled: true
    command: ["bundle", "exec", "brakeman"]
```

[bundler-audit](https://github.com/rubysec/bundler-audit) in particular has found some heinous vulnerabilities I would've never known about otherwise. The others mostly make sure I keep things consistent and secure

##### RuboCop

Some developers get very upset by the very idea of [RuboCop](https://github.com/rubocop-hq/rubocop), but I find it has a set of helpful defaults that I can always configure as needed

You may have different preferences, please use what you'll stick to consistently. Here are mine (found in `.rubocop.yml`):

```yaml
require:
  - rubocop-rspec
  - rubocop-rails

Layout/LineLength:
  Max: 100

Metrics/BlockLength:
  Exclude:
    - "spec/**/*_spec.rb"

Style/Documentation:
  Enabled: false

Style/FrozenStringLiteralComment:
  Enabled: false

Style/WordArray:
  EnforcedStyle: brackets

Style/SymbolArray:
  EnforcedStyle: brackets

Style/HashEachMethods:
  Enabled: true

Style/HashTransformKeys:
  Enabled: true

Style/HashTransformValues:
  Enabled: true

Rails:
  Enabled: true

RSpec/ExampleLength:
  Max: 10

AllCops:
  Exclude:
    - "db/schema.rb"
    - "db/migrate/*.rb"
    - "config/**/*.rb"
    - "bin/**"
  NewCops: enable
```

With these in place, we can run the following to autocorrect our application:

```bash
bundle exec rubocop -a
```

Looking at the results, it may have additional changes that it can make for you by using the `-A` flag instead of `-a`. I recommend reading closely and making sure this is a change you want to make

Let's save the changes:

```bash
git add -A
git commit -m "Rubocop fixes"
```

You should now see Overcommit run it's checks against our code. Very cool!

### React Integration

There are a trillion things we can do on the Rails side, but we'll skip those for now and get React integrated

I'm going to utilize [Create React App](https://create-react-app.dev/) because we can use the [official Redux + TypeScript template](https://github.com/reduxjs/cra-template-redux-typescript) to get a lot of groundwork done for us

As an aside, you don't have to use Redux or TypeScript, you can:

1. go with the default Create React App template
2. use [Redux's JS template](https://github.com/reduxjs/cra-template-redux) if you want to use Redux but not TypeScript
3. use [React's TypeScript template](https://github.com/facebook/create-react-app/tree/master/packages/cra-template-typescript) if you want to use TypeScript but not Redux

I like the sense of data flow and organization that Redux gives you (especially with [Redux Toolkit](https://redux-toolkit.js.org/)), and I like having some types in place to encourage me to check for `undefined` responses and just to keep things tight in general

Enough rambling! Inside my project's root folder, I run:

```bash
yarn create-react-app client --template redux-typescript
```

Next, I'm going to write a `Procfile` for my dev environment so that I can start up Rails and React at the same time

Because I have [the Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed for handling deployments, I can use it to consume my `Procfile`. But if you don't want to go that route, you can always install [`foreman`](https://github.com/ddollar/foreman) in your environment

In the root of my project, I create a file called `Procfile.dev` with the following content:

```bash
web: PORT=3000 yarn --cwd client start
api: PORT=3001 bundle exec rails s
```

The will fire up two processes:

1. `web` - Runs the `start` command defined in `client/package.json` with the port 3000
2. `api` - Runs the rails server on port 3001

If you have Heroku CLI, you can then run:

```bash
heroku local -f Procfile.dev
```

If you have foreman, you'd run:

```bash
foreman start
```

You can now check `localhost:3000` and `localhost:3001` in the browser, and you should see the default React and Rails screens

Let's save the changes:

```bash
git add -A
git commit -m "React app generation"
```

### Deployment

Rather than build everything locally, we're going to let Heroku take care of building on our deploy

In the root of the application, add a `package.json` with the following (being sure to replace the obvious placeholders...):

```json
{
  "name": "[YOUR APPLICATION NAME]",
  "license": "MIT",
  "engines": {
    "node": "[YOUR NODE VERSION]",
    "yarn": "[YOUR YARN VERSION]"
  },
  "scripts": {
    "build": "yarn --cwd client install && yarn --cwd client build",
    "deploy": "cp -a client/build/. public/",
    "heroku-postbuild": "yarn build && yarn deploy"
  }
}
```

The magic script is `heroku-postbuild` which will be triggered during Heroku's build process, so we don't have to do it on our end

Next, we're going to create a `Procfile` for production:

```bash
web: bundle exec rails s
release: bin/rails db:migrate
```

With that `release` command, the deployment will take care of migrating for us. Very cool!

Now, there are a trillion ways of handling secrets in Rails (because even in Rails 6, default secrets management sucks). I prefer [Figaro](https://github.com/laserlemon/figaro) because you can set up your "secrets" to read from the Environment, then just set up those variables locally in an uncomitted `application.yml` file, and remotely however you need (again, Heroku makes this easy with [Confi Vars](https://devcenter.heroku.com/articles/config-vars)).

For the sake of getting this dang article over with, we're just going to create a `secrets.yml` file in `config`:

```yml
development:
  secret_key_base:

test:
  secret_key_base:

production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

For both `development` and `test`, just run `bin/rake secret | pbcopy` which will generate a secrete string and then put it into your clipboard, so you can paste each as the values for `secret_key_base`

In real life, **DON'T COMMIT THIS**. You don't want your secrets key base just floating out there. Use Figaro or manually add them to the environment, whatever you need to to do.

We're so close...

Generate a new Heroku app using the Heroku CLI:

```bash
heroku apps:create
```

Next, we're going to add some [Buildpacks](https://devcenter.heroku.com/articles/buildpacks) to our Heroku app so that it knows A) what to use to build the app and B) In which order:

```bash
heroku buildpacks:add heroku/nodejs --index 1
heroku buildpacks:add heroku/ruby --index 2
```

Amazingly enough, we can deploy to Heroku right now:

```bash
git add -A
git commit -am "Heroku setup"
git push heroku master
```

Yes, Heroku still uses a `master` branch :(

You can then watch the magic happen as Heroku updates on the steps. If everyhing goes according to plan, you should see a successful deployment to your newly generated app! If you don't see the link, you can just run:

```bash
heroku open
```

And it will open in the browser for you. Tada!

### Closing Thoughts

We covered a lot here, but honestly not as much as I intended. I've created an Additional Resources section below with some articles that can help you expand on what is here. A couple of suggestions

#### <abbr title="Continuous Integration / Continuous Deployment">CI/CD</abbr>

[CI/CD](https://www.infoworld.com/article/3271126/what-is-cicd-continuous-integration-and-continuous-delivery-explained.html) can make running tests and deploying to different environments way easier than trying to handle in manually on your own

[Ansible](https://www.ansible.com/) is one of the industry standard approaches

Personally, I've used [Semaphore](https://semaphoreci.com/) and [Travis CI](https://travis-ci.org/), and they are both pretty intuitive to get started

Semaphore also has documentation on [doing Heroku deployments through Semaphore](https://docs.semaphoreci.com/examples/heroku-deployment/)

#### Code Analysis

While we have `brakeman` and `rubocop` locally to cover a lot of code quality bits, it can also be useful to have a sense of other less common metrics, like code duplication and smells

I've used [Quality by Code Climate](https://codeclimate.com/quality/) and I find it very intuitive. It's even caught smells that `rubocop` has not (which you may not like, but it's easy to customize what it reports and what it doesn't)

You can also set it up to report test coverage. While I think [test coverage is overrated](https://martinfowler.com/bliki/TestCoverage.html) as a metric, it can at the very least point out code that you may have though was tested but wasn't. Code Climate provides [documentation on configuring test coverage](https://docs.codeclimate.com/docs/configuring-test-coverage) with a number of different CI builds, including [Travis](https://docs.codeclimate.com/docs/travis-ci-test-coverage) and [Semaphore](https://docs.codeclimate.com/docs/semaphore-ci-test-coverage-example)

#### Error Reporting

When errors happen in production, it can sometimes be a pain to track down the source. Sure, you can have debug logging throughout. Sure, you can configure what gets logged (since Rails likes to log everything by default) using [lograge](https://github.com/roidrage/lograge)

But errors will still happen, and you'll need to figure out why

There are several solutions out there. The most popular ones I've come across are [bugsnag](https://www.bugsnag.com/), [rollbar](https://rollbar.com/solutions/error-monitoring/), and [honeybadger](https://www.honeybadger.io/). I tend to prefer honeybadger, only because it's incredibly easy to set up for Ruby on Rails

The benefit is that, when the error occurs, you get all of the environment variables and the stack trace (which would be performance-inducing to log out all the time), so that you can see right where the error occurred

The biggest help for me has been having it for scheduled ActiveJobs that **don't** write to the logs, so debugging without some context can be a pain

#### Okay, that's all

Thank you for reading, I hope this is helpful! If you want to see several of the suggested ideas applied to a repository, you can look at my sample [CRM Repo](https://github.com/blrobin2/crm). Please feel free to clone it and play around (it's still very much a <abbr title="Work In Progess">WIP</abbr>), as well as submit any Pull Requests

### Additional Resources

#### Articles

- [Heroku: Deploying Using Docker](https://devcenter.heroku.com/categories/deploying-with-docker)
- [Rails API Only Course: Setup Rails Application Boilerplate](https://duetcode.io/rails-api-only-course/setup-rails-application-boilerplate)
- [Git: Renaming the "master" branch](https://dev.to/rhymu8354/git-renaming-the-master-branch-137b)
- [How to Get RSpec to Skip View Specs When You Generate Scaffolds](https://www.codewithjason.com/get-rspec-skip-view-specs-generate-scaffolds/)
- [How to Get "create-react-app" to work with your Rails API](https://www.newline.co/fullstack-react/articles/how-to-get-create-react-app-to-work-with-your-rails-api/)
- [A Rock Solid, Modern Web Stack — Rails 5 API + ActiveAdmin + Create React App on Heroku](https://blog.heroku.com/a-rock-solid-modern-web-stack)
- [ActiveModel Form Objects](https://thoughtbot.com/blog/activemodel-form-objects)

#### Books

- [Component-Based Rails Applications](https://cbra.info/)
- [Effective Testing with RSpec 3](https://pragprog.com/titles/rspec3/effective-testing-with-rspec-3/)

#### Repos

- [Infinitum's JSON API Example](https://github.com/infinum/rails-infinum-jsonapi_example_app_old)
- [React Redux JWT Auth Example](https://github.com/joshgeller/react-redux-jwt-auth-example)
