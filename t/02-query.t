#!/usr/bin/env perl6

use lib 'lib';
use DB::Xoos::SQL;
use Test;

plan 4;

class A does DB::Xoos::SQL { };

my $s = A.new(:!inflate);
my $f = {
  '-and' => [
    'w.x' => { '>' => 5 },
    'w.x' => { '<' => 500 },
  ],
  '-or' => [
    'w.y' => { '>' => 1 },
    'w.y' => -1,
  ],
};

my $o = {
  join => [
    {
      table => "judo",
      on => [ 'a' => 'a' ],
    },
  ]
};

my %sq = $s.sql-select($f, $o);

ok %sq<sql> ~~ m:i{^^'SELECT * FROM "dummy" as self left outer join "judo" on ( "judo"."a" = "self"."a" ) WHERE '}, 'SELECT * FROM "dummy" as self left outer join "judo" on ( "a" = "a" ) WHERE';
ok %sq<sql> ~~ m:i{('AND'?)'( ( "w"."y" '('>'|'=')' ? ) OR ( "w"."y" '('='|'>')' ? ) )'}, 'clause 1';
ok %sq<sql> ~~ m:i{('AND'?)'( ( "w"."x" '('>'|'<')' ? ) AND ( "w"."x" '('<'|'>')' ? ) )'}, 'clause 2';
is-deeply %sq<params>.sort, [-1,1,5,500].sort, 'got the params right';
