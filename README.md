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
