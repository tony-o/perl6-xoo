#!/usr/bin/env perl6

use lib 'lib';
use lib 't/lib';
use DBO;
use Test;
use DBO::Test;
use DBIish;

configure-sqlite;

my $cwd = $*CWD;
$*CWD = 't'.IO;

my DBO $d .=new;
my $db     = DBIish.connect('SQLite', database => 'test.sqlite3');

$d.connect(:$db, :options({
  prefix => 'X',
}));

my ($sth, @raw, $scratch);
my $hello = $d.model('Hello');
my @rows = $hello.search({ id => 1 }).all;

ok @rows.elems == 1, 'should have one row with id = 1';
ok @rows[0].txt eq 'hello world', '.txt eq "hello world"';
ok @rows[0].id == 1, 'the .id is, in fact, 1';

@rows = $hello.search({ txt => { '<>' => 'hello world' } }).all;
$sth = $db.prepare(q:to/SSS/);
select * from hello where txt <> 'hello world';
SSS
$sth.execute;
@raw  = $sth.allrows(:array-of-hash);

ok @rows.elems == @raw.elems, 'ORM should return same number of rows as artisinal handcrafted query';
$scratch = 0;
for @rows -> $r {
  $scratch += @raw.grep({ $_<id> eq $r.id && $_<txt> eq $r.txt }).elems ?? 1 !! 0;
}
ok $scratch == @rows.elems, 'data matches between raw query and DBO';

@rows = $hello.search({ txt => { 'like' => '% %' } }).all;
ok @rows.elems == 1, 'should have one row with: txt like "% %"';
ok @rows[0].txt eq 'hello world', '.txt eq "hello world"';
ok @rows[0].id == 1, 'the .id is, in fact, 1';

my $cnt = $hello.search({ txt => { like => '% %' } }).count;
ok $cnt == 1, '.count for (txt like "% %") should be only 1';

$hello.search({ txt => { 'not like' => '% %' }}).update({ txt => 'abc' });
@rows = $hello.search.all;
say '======================';
say '| id  | txt          |';
say '======================';
for @rows -> $r {
  say "| {$r.id}{' ' x 4 - $r.id.Str.chars}| {$r.txt}{' ' x 13-$r.txt.chars}|";
}
say '======================';
say "\n";

$*CWD = $cwd;
