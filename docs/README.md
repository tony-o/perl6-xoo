# Welcome to Xoos

This is the documentation for Xoos, a perl6 ORM.

## 

* [terminology](#terminology)
  * [model](#model)
  * [row](#row)
* [order of operations](#order-of-operations)
  * [bootstrapping](#bootstrapping)
    * [connect](#connect)
      * [options](#options)
        * [$prefix](#prefix)
        * [@model-dirs](#model-dirs)
      * [DSN vs DB](#dsn-vs-db)
        * [DSN](#dsn)
        * [DB](#db)
* [models](#models)
  * [loading](#loading)
* [yaml model files](#yaml-model-files)


# terminology

## model

a model describes a table.  anything in your `Model/` can contain methods to act upon that data, ie `Model::Customer` might contain a convenience method `outstanding-invoice-balance` that returns the monetary value of all unpaid invoices

## row

describes a row of the table.  anything in your `Row/` can contain methods to act upon one data, ie 'Row::Invoice` might contain a method `mark-paid` that marks the invoice paid and updates your other accounting tables

# order of operations

## bootstrapping

### .connect

`connect` is overloaded as `connect(Any:D: :$db, :%options)` or `connect(Str:D $dsn, :%options)`.  More about DSN vs DB below.

This method is templated in `DB::Xoos` and implemented in the respective `DB::Xoos::<Driver>`, see those files for more in depth in what is happening in the one you're interested in.

When connect is called, models and rows loading is attempted with any problems `warn`ed to stdout.

#### `%options`

##### `$prefix`

This is the prefix to use when attempting to load Models.  ie `:prefix<X>` attempts to load models and rows from `X/Model|Row/\*`

##### `@model-dirs`

Use this option to load models and rows from YAML files

#### DSN vs DB

##### DSN

you can use either a DSN or use an existing DB connection to start Xoos.

DSN format is `<driver>://(<user>:<pass>@)?<host>(:<port>)?/(<database>)?`.  the database name is optional for drivers like `sqlite`

##### DB

Xoos ships with `MySQL|Oracle|Pg|SQLite` and they all use `DBIish`, if you need to use `DB::Pg` then please consider contributing either to the ecosystem or this repo and use `DB::Xoos::Pg\(::\*\)` as a template

You can pass `.connect` an existing connection 


# models

models should inherit from `DB::Xoos::Model[Str:D $table-name, Str:D $row-class?]` where `$table-name` is mandatory and `$row-class` will attempt to auto load the `Row` class based on the model's name

## loading




# yaml model files

yaml model files are optional and ultimately depend on how you want to look at the structure of your tables in code.  the format of the yaml file is very similar to the perl6 format but here might be a typical layout (see model documentation for more info about what these options mean)

```yaml
table: customer
name: Customer
columns:
  customer_id:
    type: integer
    nullable: false
    is-primary-key: true
    auto-increment: true
  name:
    type: text
  relations:
    invoice:
      has-many: true
      model: Invoice
      relate:
        invoice_id: customer_id
    open-invoices:
      has-many: true
      model: Invoice
      relate:
        invoice_id: customer_id
        +status: closed
```
