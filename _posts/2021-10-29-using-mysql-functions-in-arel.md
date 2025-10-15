---
layout: post
title: "Using SQL Functions in Arel"
excerpt: "Let Arel handle the query building, even when Arel/ActiveRecord doesn't support the function"
category: programming
---

### What is Arel?

[Arel](https://github.com/rails/arel) is the library that functions as the foundation for Ruby on Rails' [ActiveRecord](https://rubygems.org/gems/activerecord) library, specifically for translating an AST of query pieces into a functional SQL query.

For most users, just using ActiveRecord gives you enough of what you need to build your queries. By putting that famous syntatic sugar on top of complex operations, you can get very expressive in ActiveRecord with little work.

However, for people who come from SQL backgrounds (or for people such as myself who have to do a fair number of reports where performance dictates all computations are done within SQL), you can sometimes hit snags where it isn't obvious what you need to do to build out your query.

### Context

For the sake of keeping this article short, I'm going to assume that you know about `Arel.sql`, [ActiveRecord's query sanitization methods](https://api.rubyonrails.org/classes/ActiveRecord/Sanitization/ClassMethods.html) and all that, but you are in a use-case where you need to maintain as much of the SQL you are building up as code, letting Arel take care of building out the SQL for you.

If you are unsure, a use case for me is that I have to do a fair bit of reporting queries on tables with millions upon millions of rows, so I need to build up fairly complex SQL to ensure I query for just what I need. These queries often include deeply-nested subqueries, many which get repeated, and self-joins on hierachical tables where I need to control the name aliases.

All of this is doable with just ActiveRecord, but these queries become pretty tough to maintain over time, and you end up repeating pieces of query just to make sure they work in the specific context.

### Example

I was passed a MySQL query that I needed to be able to dynamically build up. One piece that recurred wat the following:

```sql
WHERE SUBSTRING(`users`.`email`, LOCATE(`users`.`email`, '@') + 1) != 'somedomain.com'
```

For those who do not know this, the above segment extracts the domain name from an email address, and then checks to see if the domain name in the `email` column is not 'somedomain.com'. Due to how the query was built, the `users` table was sometimes aliased, this query was a repeated subquery for other wheres, and the domain name checked against could be some other domain i.e. 'google.com'.

Basically, I needed a degree of control to where I wasn't confident in what I could achieve with just ActiveRecord, and I definitely didn't want to just pass around repetitious SQL. I'm not saying you CAN'T do this with just ActiveRecord methods, I'm saying I chose the following path because it worked best for my team's workflow (and sanity).

First, I will show you the final segment of code (albeit simplified a bit to keep the focus clear):

```ruby
class UsersQuery
#...
  def call(domain_name)
    User.connection.exec_query(query(domain_name))
  end

  def query(domain_name)
    users.where(email_domain.not_eq(domain_name)).to_sql
  end

  def users
    User.arel_table
  end

  def email_domain
    substring(users[:email], plus(locate(users[:email], '@'), 1))
  end

  def substring(field, value)
    named_function('SUBSTRING', field, value)
  end

  def plus(left, right)
    Arel::Nodes::InfixOperation.new('+', left, right)
  end

  def locate(field, string)
    named_function('LOCATE', field, sql_literal(string))
  end

  def named_function(function_name, *args)
    Arel::Nodes::NamedFunction.new(function_name, args)
  end

  def sql_literal(string)
    Arel::Nodes::SqlLiteral.new("'#{string}'")
  end
end
```

For the query, we build it up using Arel and then call `to_sql` to get the SQL query that we will execute against a connection to the database. We build the query against the `arel_table` that is pulled from the `User` class. We then use a series of custom functions to build up our computed `WHERE` segment using three classes provided by arel: [`SqlLiteral`, `NamedFunction`, and `InfixOperation`](https://www.rubydoc.info/gems/arel/Arel/Nodes).

Seeing the original SQL, you may understand the code version without having to read any further. But for those who would like a little more explanation, I will break down my choices below.

As an aside, I wrapped the direct calls to Arel classes mostly to reduce noise in trying to read what each methods does. Also, if I were going to be using these in multiple places, it would benefit me to extract these methods to their own shared module.

#### `SqlLiteral`

For safety purposes, Arel does not allow you to pass raw strings to custom functions, meaning they need to be converted into a SQL literal. Here, the '@' is what needed to be converted into a SQL literal in order to be passed to 'LOCATE', so we wrap this call into a method I named `sql_literal`.

### `NamedFunction`

For functions where you pass arguments between parentheses, `NamedFunction` allows you to pass the name of the function and then an array of the arguments to pass to that function. I used a spread operator for my `named_function` so that every argument after the function name is treated as an argument to that function. Not necessary, but I thought it made the code a tiny bit cleaner.

### `InfixOperation`

Finally, for functions that are called between their arguments (such as `+` or `>=`), `InfixOperation` allows you to pass the name of the operator, followed by the values to put to the left and right of the operator.

### Arel Extensions

You may also be familiar with a library called [Arel Extension](https://github.com/Faveod/arel-extensions), which extends the Arel code to include these operations for you. The following demonstrates how to do the above using this library:

```ruby
class UsersQuery
  ArelExtensions::CommonSqlFunctions.new(User.connection).add_sql_functions

  def call(domain_name)
    User.connection.exec_query(query(domain_name))
  end

  def query(domain_name)
    users.where(email_domain.not_eq(domain_name)).to_sql
  end

  def users
    User.arel_table
  end

  def email_domain
    users[:email].substring(users[:email].locate('@') + 1)
  end
end
```

Unfortunately, when using this, I ran into issues where [queries generated by ActiveRecord elsewhere would general SQL that was not compatible with MySQL](https://github.com/jbox-web/ajax-datatables-rails/issues/377), so I ended up removing it and using the solution I first presented. I would much prefer to use the extensions if I didn't have the other issue, and you may be able to do so without running into any issues.

### Conclusion

ActiveRecord is a really nice ORM for handling queries, and part of what makes it so nice is that it provides top-level abstractions for simple queries, and a way to step down into Arel for composing complex queries. By allowing me to define invidiual methods for each piece of my queries, I get the advantage of SQL's performance while still having DRY code.

Hopefully this was useful to you!

### Additional Resources

- [Using Arel to build complex SQL expressions](https://tanzu.vmware.com/content/blog/using-arel-to-build-complex-sql-expressions)
- [MySQL manually defined order the Arel Way](https://kyles.work/code/mysql-manually-defined-order-the-arel-way)
- [Using Arel to compose SQL queries](https://thoughtbot.com/blog/using-arel-to-compose-sql-queries)
