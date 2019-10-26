#!/usr/bin/env perl6

use lib 'lib';
use lib 't/lib';
use Test;
use DB::Xoos::Test;
use DB::SQLite;

plan 6;

try 'test.sqlite3'.IO.unlink;
configure-sqlite;

my $cwd = $*CWD;
$*CWD = 't'.IO;

my $d  = get-sqlite;
my $db = $d.db;

my ($sth, $scratch);
my $customers = $d.model('Customer');
my $orders    = $d.model('Order');

my $c      = $customers.new-row;
$c.name('customer 1');
$c.contact('joe schmoe');
$c.country('usa');
$c.update;

ok $c.orders.count == 0, 'should have no orders in fresh order table';
for 0..^5 {
  my $o = $orders.new-row;
  $o.set-columns(
    status => ($_ < 3) ?? 'closed' !! 'open',
    customer_id => $c.id,
    order_date => time,
  );
  $o.update;
}

ok $c.orders.count == 5, 'should have 5 orders after inserts';
ok $c.open_orders.count == 2, 'should have 2 open orders after inserts';
$c.orders.close;
ok $c.open_orders.count == 0, 'should have 0 open orders after &X::Model::Order::close';

my $first = $c.orders.first;
my $copy  = $first.reopen-duplicate;
my $expc   = $db.query('select id from `order` where status = \'open\'').hashes[0]<id>;

isnt $first.id//-2, $copy.id//-1, "duplicated order should have different id";
is $copy.id//-1, $expc, "duplicated order should have .id = $expc";

$*CWD = $cwd;
