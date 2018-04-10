# DBO

DBO is an ORM designed for convenience and ease of use, it is modeled after DBIx::\* if you're into that kind of thing already (note: some concepts and names have deviated).  

## what works

* relationships
* row object inflation (calling .first on a query returns a DBO::Row)
* row objects inherit from the model::@columns
* model level convenience methods
* row level convenience methods

## todo

* column type and data validation hooks
* decouple SQL generation from DBO::Searchable (this includes decoupling the SQL generation from the DB layer)
* look at YAML generation of models
* validation of model/table/relationships when model loads
* prefetch relationships option

# DBO::Model

What is a model?  A model is essentially a table in your database.  Your ::Model::X is pretty barebones, in this module you'll defined `@.columns` and `@.relations` (if there are any relations).

## Example

```perl6
use DBO::Model;
# the second argument below is optional and also accepts a type.
# if the arg is omitted then it attempts to auto load ::Row::Customer
unit class X::Model::Customer does DBO::Model['customer', 'X::Row::Customer']; 

has @.columns = [
  id => {
    type           => 'integer',
    nullable       => False,
    is-primary-key => True,
    auto-increment => 1,
  },
  name => {
    type           => 'text',
  },
  contact => {
    type => 'text',
  },
  country => {
    type => 'text',
  },
];

has @.relations = [
  orders => { :has-many, :model<Order>, :relate(id => 'customer_id') },
  open_orders => { :has-many, :model<Order>, :relate(id => 'customer_id', '+status' => 'open') },
  completed_orders => { :has-many, :model<Order>, :relate(id => 'customer_id', '+status' => 'closed') },
];
```

In this example we're creating a customer model with columns `id, name, contact, country` and relations with specific filter criteria.  You may notice the `+status => 'open'` on the open\_orders relationship, the `+` here indicates it's a filter on the original table.

### Breakdown

`class :: does DBO::Model['table-name', 'Optional String or Type'];`

Here you can see the role accepts one or two parameters, the first is the DB table name, the latter is a String or Type of the row you'd like to use for this model.  If no row is found then DBO will create a generic row and add helper methods for you using the model's column data.

`@.columns`

A list of columns in the table.  It is highly recommended you have *one* `is-primary-key` or `.update` will have unexpected results.

`@.relations`

This accepts a list of key values, the key defining the accessor name, the later a hash describing the relationship.  `:has-one` and `:has-many` are both used to dictate whether a DBO model returns an inflated object (:has-one) or a filterable object (:has-many).

## Methods

### search(%filter?, %options?)

Creates a new filterable model and returns that.  Every subsequent call to `.search` will _add_ to the existing filters and options the best it can.

Example:

```
my $customer = $dbo.model('Customer').search({ name => { like => '%bozo%' }, });
# later on ...
my $geo-filtered-customers = $customer.search({ country => 'usa' });
# $geo-filtered-customers effective filter is:
#   {
#      name => { like => '%bozo%' },
#      country => 'usa',
#   }
```

### .all(%filter?)

Returns all rows from query (an array of inflated `::Row::XYZ`).  Providing `%filter` is the same as doing `.search(%filter).all` and is provided only for convenience.

### .first(%filter?, :$next = False)

Returns the first row (again, inflated `::Row::XYZ`) and caches the prepared statement (this is destroyed and ignored if $next is falsey)

### .next(%filter?)

Same as calling `.first(%filter, :next)`

### .count(%filter?)

Returns the result of a `select count` for the current filter selection.  Providing `%filter` results in `.search(%filter).count`

### .delete(%filter?)

Deletes all rows matching criteria.  Providing `%filter` results in `.search(%filter).delete`

### insert(%field-data)

Creates a new row in the database, return value is Nil.  If you'd like a `::Row::XYZ` returned, then create the row, update the values, and then save (see `DBO::Row::`)

