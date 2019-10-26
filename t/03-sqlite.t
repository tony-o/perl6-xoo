#!/usr/bin/env perl6

use lib 't/lib';
use Test;
use DB::Xoos::Test;
use DB::SQLite;

plan 16;

configure-sqlite;

my $cwd = $*CWD;
$*CWD = 't'.IO;

my $d  = get-sqlite;
my $db = $d.db;

my ($sth, @raw, $scratch);
my $hello = $d.model('Hello');
my @rows = $hello.search({ id => 1 }).all;

ok @rows.elems == 1, 'should have one row with id = 1';
ok @rows[0].txt eq 'hello world', '.txt eq "hello world"';
ok @rows[0].id == 1, 'the .id is, in fact, 1';

@rows = $hello.search({ txt => { '<>' => 'hello world' } }).all;
$sth = $db.query(q:to/SSS/);
select * from hello where txt <> 'hello world';
SSS
@raw  = $sth.hashes;

is @rows.elems, @raw.elems, 'ORM should return same number of rows as artisinal handcrafted query';
$scratch = 0;
for @rows -> $r {
  $scratch += @raw.grep({ $_<id> eq $r.id && $_<txt> eq $r.txt }).elems ?? 1 !! 0;
}
ok $scratch == @rows.elems, 'data matches between raw query and Xoo';

@rows = $hello.search({ txt => { 'like' => '% %' } }).all;
ok @rows.elems == 1, 'should have one row with: txt like "% %"';
ok @rows[0].txt eq 'hello world', '.txt eq "hello world"';
ok @rows[0].id == 1, 'the .id is, in fact, 1';

my $cnt = $hello.search({ txt => { like => '% %' } }).count;
ok $cnt == 1, '.count for (txt like "% %") should be only 1';

$hello.search({ txt => { 'not like' => '% %' }}).update({ txt => 'abc' });
@rows = $hello.search.all;
$cnt  = { 'hello world' => 0, 'abc' => 0 };
for @rows {
  $cnt{$_.txt}++;
}

ok $cnt{'hello world'} == 1, 'did not update the only row containing a space';
ok $cnt<abc> == @rows.elems - 1, 'updated all rows not containing a space';

$hello.search({ txt => { 'not like' => '% %' }}).delete;
$cnt = $hello.search({ txt => { 'not like' => '% %' }}).count;
ok $cnt == 0, 'not like "% %" should be 0 after delete';

$hello.search({ txt => { 'not like' => '% %' }}).update({ txt => 'abc' });
@rows = $hello.all;
$cnt  = { 'hello world' => 0, 'abc' => 0 };
for @rows {
  $cnt{$_.txt}++;
}

ok $cnt{'hello world'} == 1, 'did not update the only row containing a space';
ok $cnt<abc> == @rows.elems - 1, 'updated all rows not containing a space';


$hello.insert({ txt => 'hey bucko' });
$hello = $d.model('Hello').search({ id => { '>' => -1 }});

isnt $hello.first.id, $hello.next.id, '.first and .next dont return same result';
is $hello.next, Nil, '.next should return Nil when no more data available';

$*CWD = $cwd;

# vi:syntax=perl6
