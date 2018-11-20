# Welcome to Xoo

This is the documentation for Xoo, a perl6 ORM.

## 

* [terminology](#terminology)
* [a model's structure](#a-models-structure)
* [yaml model files](#yaml-model-files)


# terminology

## models

a model describes a table.  anything in your `Model/` can contain methods to act upon that data, ie `Model::Customer` might contain a convenience method `outstanding-invoice-balance` that returns the monetary value of all unpaid invoices

## row

describes a row of the table.  anything in your `Row/` can contain methods to act upon one data, ie 'Row::Invoice` might contain a method `mark-paid` that marks the invoice paid and updates your other accounting tables

# a model's structure

test-link

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
