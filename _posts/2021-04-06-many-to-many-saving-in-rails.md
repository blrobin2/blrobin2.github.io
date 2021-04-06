---
layout: post
title: "Many-to-Many Saving in Rails"
excerpt: "It's very easy if you know how to do it"
category: programming
---

Whenever you search online for 'how to save many-to-many relationships in Rails using form helpers' or some equivalent inquiry, you might discover a number of different approaches. Some have special helpers written into the controller, others may hijack the `autosave_associated_records_for_{field}` hook

And they all work. But they're also not necessary __most__ of the time

### Simple Example: Authors and Books (`has_and_belongs_to_many`)

Depending on who you talk to (or your Rubocop configuration), `has_and_belongs_to_many` is either totally fine for simple use cases or a bad practice that hides a table from your associations

I'm not here to preach one way or the other. But if you happen to use it, saving your associations is much easier than you may think

#### Code Setup
This demo will assume you have a Rails project already set up. If not, you can just do `rails new association_saving` or something to get a skeleton project

Once you have a project, generate a migration:

`bin/rails g migration create_authors_and_books`

`db/migrate/[timestamp]_create_authors_and_books.rb`
```ruby
class CreateAuthorsAndBooks < ActiveRecord::Migration[6.1]
  def change
    create_table :authors do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.timestamps
    end

    create_table :books do |t|
      t.string :title
      t.timestamps
    end

    create_table :authors_books, id: false do |t|
      t.belongs_to :author, null: false
      t.belongs_to :book, null: false
    end

    add_foreign_key :authors_books, :authors
    add_foreign_key :authors_books, :books
  end
end
```

After running `bin/rails db:migrate`, create your models. I've added some basic validations just to keep myself from getting in trouble

`app/models/author.rb`
```ruby
class Author < ApplicationRecord
  has_and_belongs_to_many :books

  validates :first_name, presence: true
  validates :last_name, presence: true

  def name
    "#{first_name} #{last_name}"
  end
end
```

`app/models/book.rb`
```ruby
class Book < ApplicationRecord
  has_and_belongs_to_many :authors

  validates :title, presence: true
  validates :authors, presence: true
end
```

Since we're not going to go through creating an Author through the UI, we can add a couple of Authors to our `db/seeds.rb`:

```ruby
Author.create(first_name: 'Ernest', last_name: 'Hemingway')
Author.create(first_name: 'William', last_name 'Faulkner')
```

and then run `bin/rails db:seed`

Finally, you can create your own controller and views however you wish. Since this is a demo, I'm going to generate them:

`bin/rails g scaffold_controller book title:string`

Add the following to `app/controllers/books_controller.rb`:

```ruby
  # omitted: start of class and other methods
  #...
  def new
    @book = Book.new
    @authors = Author.order(:last_name)
  end

  # .. more method

  private


  # Only allow a list of trusted parameters through.
  def book_params
    # Replace the generated content with the following:
    params.require(:book).permit(:title, { author_ids: [] })
  end
```

We create a list of `@authors` that we can use to populate our `select` here shortly. In addition, we set the [strong parameters](https://api.rubyonrails.org/v6.1.3/classes/ActionController/StrongParameters.html) to permit the acceptance of a `title` field, as well as an array of `author_ids`

#### Saving with `form_helpers`

Within `app/views/books/_form.html.erb` (or wherever your save form is located):

```ruby
  # ... start of form
  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>

  # Add the following:
  <div class="field">
    <%= form.label :author_ids, 'Authors' %>
    <%= form.collection_select :author_ids, @authors, :id, :name, {}, { multiple: true } %>
  </div>

  # ... rest of form
  <div class="actions">
    <%= form.submit %>
  </div>
```

For those unfamiliar, [`collection_select`](https://apidock.com/rails/ActionView/Helpers/FormOptionsHelper/collection_select) allows you generate a `select` tag with `options` populated by an array of `ActiveRecord` objects. Here in this case, we are saying that, within our form, we are going to submit a field called 'author_ids'. The collection we are using is the `@authors` that we assigned in the controller. For the `value` of each `option` tag, we are using the `:id` of the Author. For the display text, we are using our `:name` method that we defined in the Author model. Finally, we are able to pass in two sets of options: the first are general options (for example, if you wanted to have the first option be prompt text, you could set `prompt` to `true` or some custom text), the second set are html_options, which we can use to configure the generate HTML. In our case, because we have a many-to-many association, we want a multiple select

Now, whenever you have something selected, the `Save` button is clicked, and `@book.save` is called, your `authors_books` table will be populated with the association!


#### Saving without `form_helpers`

That's all well and good if you're using Rails as a [monolith](https://martinfowler.com/bliki/MonolithFirst.html). But this is the 2020s, and microservices are all the rage, so you may be using Rails as an API layer. Your frontend could be Vue, React, Stimulus, Angular... the options are truly endless.

But, for all of them, if Rails is receiving the `create` and `update` params the same way as above, your UI can still be simple.

In other words, so long as your `POST` or `PUT` request takes the following shape:
```json
{
  "book": {
    "title": "Some Title",
    "author_ids": [1, 2, 3] // or whatever the IDs are for your authors
  }
}
```

Then Rails is going to be able to save your associations without issue

### Complex example: Products, Orders, and LineItems (`has_many through`)

In this scenario, our join table is going to have fields of its own to manage, so we will need to utilize `has_many through` so that:
* the join table has its own model (LineItem)
* we can target the table in the attributes we send across

#### Code Setup

Again, assuming you have a project already set up, generate a migration:

`bin/rails g migration create_products_orders_and_line_items`

`db/migrate/[timestamp]_create_products_orders_and_line_items.rb`
```ruby
class CreateProductsOrdersAndLineItems < ActiveRecord::Migration[6.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :orders do |t|
      t.text :description, null: false
      t.timestamps
    end

    create_table :line_items do |t|
      t.belongs_to :product, null: false
      t.belongs_to :order, null: false
      t.integer :quantity
    end

    add_foreign_key :line_items, :products
    add_foreign_key :line_items, :orders
  end
end
```

After running `bin/rails db:migrate`, create your models. I've added some basic validations just to keep myself from getting in trouble


`app/models/product.rb`
```ruby
class Product < ApplicationRecord
  has_many :line_items
  has_many :orders, through: :line_items

  validates :name, presence: true
end
```

`app/models/order.rb`
```ruby
class Order < ApplicationRecord
  has_many :line_items
  has_many :products, through: :line_items

  validates :description, presence: true

  accepts_nested_attributes_for :line_items,
                                reject_if: proc { |attrs| attrs['quantity'].nil? },
                                allow_destroy: true
end
```

`app/models/line_item.rb`
```ruby
class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :order

  validates :quantity, presence: true, numericality: { only_integer:true, greater_than_or_equal_to: 1 }
end
```

Besides the use of `has_many through:`, the other new component is the `accepts_nested_attributes_for`. This will allow us to populate our join table from our orders form. The `reject_if` `proc` will reject any entries passed that have a blank quantity. For 0 or negative entries, our model validation will take care of informing the user of those cases


Since we're not going to go through creating a Product through the UI, we can add a couple of Products to our `db/seeds.rb`:

```ruby
Product.create(name: 'Spoon')
Product.create(name: 'Fork')
Product.create(name: 'Spork')
```

Finally, you can create your own controller and views however you wish. Since this is a demo, I'm going to generate them:

`bin/rails g scaffold_controller order description:text`

Add the following to `app/controllers/orders_controller.rb`:

```ruby
  # omitted: start of class and other methods
  #...
  def new
    @order = Order.new
    @products = Product.order(:name)
    @products.size.times { @order.line_items.build }
  end

  # .. more method

  private


  # Only allow a list of trusted parameters through.
  def book_params
    # Replace the generated content with the following:
    params.require(:order).permit(:description, { line_items_attributes: [:id, :product_id, :quantity, :_destroy] })
  end
```

We create a list of `@products` that we can use to populate our `select` here shortly, as well as pre-populating the order record with some empty line items. Since we created 3 products through the seeder, this will create 3 empty records, and the form will display 3 line items sections for us. Dynamically adding/removing line items is not something you can do out of the box with Rails, but is fairly trivial to handle with JavaScript of some sort (not demonstrated here).

In addition, we set the [strong parameters](https://api.rubyonrails.org/v6.1.3/classes/ActionController/StrongParameters.html) to permit the acceptance of a `description` field, as well as the fields we need to create/update/destroy associations.

Common mistakes I see here:
* Ommitting the `:id`, which leads to duplicate records being created every time you save. If you allow the save to recieve the `id`, you don't have to worry about duplications
* Ommitting the `_destroy`, which means that you cannot remove records once they've been created

#### Saving with `form_helpers`

Within `app/views/orders/_form.html.erb` (or wherever your save form is located):

```ruby
  # ... start of form
  <div class="field">
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>

  # Add the following:
  <fieldset>
    <legend>Line Items:</legend>
    <ul>
    <%= form.fields_for :line_items do |line_item_form| %>
      <li>
        <%= line_item_form.check_box :_destroy %>
        <%= line_item_form.label :quantity %>
        <%= line_item_form.number_field :quantity, step: 1, min: 1 %>
        <%= form.collection_select :product_id, @products, :id, :name %>
      </li>
    <% end %>
    </ul>
  </fieldset>

  # ... rest of form
  <div class="actions">
    <%= form.submit %>
  </div>
```

Here, we utilize [nested forms](https://guides.rubyonrails.org/form_helpers.html#nested-forms), so that Rails can understand that we are passing nested attributes through the form. Rails is smart enough to know when you've checked the `_destroy` check box if it's a new record or existing one, so we can display it no matter what

Like above, all you need to do is hit `Save` and when `@order.save` is called, it will handle populating the `line_items` table for you!

#### Saving without `form_helpers`

See my section above about different front-end frameworks and all that. For this scenario, so long as your `POST` or `PUT` request takes the following shape:
```json
{
  "order": {
    "description": "A description for the order that is being placed",
    "line_items_attributes": [
      // This record will be updated on save
      {
        "id": 1,
        "product_id": 1,
        "quantity": 4
      },
      // This record will be destroyed on save
      {
        "id": 2,
        "product_id": 1,
        "quantity": 5,
        "_destroy": true
      },
      // This record will be created on save
      {
        "product_id": 2,
        "quantity": 3
      }
    ]
  }
}
```

Then Rails is going to be able to save your associations without issue

### Summary

Hopefully this was helpful to you, and that it makes your future Rails association saving much simpler. Good luck!