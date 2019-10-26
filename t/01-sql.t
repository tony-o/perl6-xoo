#!/usr/bin/env perl6

use lib 'lib';
use DB::Xoos::SQL;
use Test;

plan 18;

my $s  = DB::Xoos::SQL.new;
my %ah = ( a=>5,c=>6 );
my %ch = ( d=>8, '-or' => [(b=>500),(b=>400)] );
my %ao = ( fields => [qw<a>] );
my $tv = 1;
my %co = ( fields => [qw<a c d>], join => [
  { table => 'world', as => 'w', on => [('w.a' => 'a'), (l => $tv)] },
]);
my $a = $s.sql-select(%ah, %ao);
my $c = $s.sql-select({ %ah, %ch }, %co);
my $d = $s.sql-select({}, { order-by => [ a => 'DESC', 'b' ] });

ok $a<sql> ~~ m:i{^^'SELECT "a" FROM "dummy" as self WHERE ( "self"."' ('c'|'a') '" = ? ) AND ( "self"."' ('a'|'c') '" = ? )'$$}, 'basic select';
is $a<params>.sort, [5,6], 'basic select params';

ok $c<sql> ~~ m:i{^^'SELECT "a", "c", "d" FROM "dummy" as self left outer join "world" as w on ( "w"."a" = "self"."a" ) and ( "w"."l" = ? ) WHERE '}, 'join sql';
is $c<params>[0], 1, 'join sql param correct';
is $c<params>.sort, [1, 5, 6, 8, 400, 500], 'join sql params';

ok $d<sql> ~~ m:i{^^'select * from "dummy" as self order by a desc, b asc'$$}, 'order by sql';
is $d<params>, [], 'order by with no filter has no params';

my $sq = $s.sql-select;
ok $sq<sql> ~~ m:i{^^'SELECT * FROM "dummy" as self'}, 'SELECT * FROM "dummy" as self';
ok $sq<params>.elems == 0, 'should be no params for first query';

$sq = $c;
ok $sq<sql> ~~ m:i{
  ^^
    'SELECT "a", "c", "d" FROM "dummy" as self left outer join "world" as w on '
    ( '( "w"."a" = "self"."a" )' || '( "w"."l" = ? )' )
    ' AND '
    ( '( "w"."l" = ? )' || '( "w"."a" = "self"."a" )' )
    ' WHERE '
}, 'SELECT "a", "c", "d" FROM "dummy" as self left outer join "world" as w on ( "w"."a" = "a" ) AND ( "l" = ? ) FROM ( ( "b" = ? ) OR ( "b" = ? ) ) AND ( "a" = ? ) AND ( "d" = ? ) AND ( "c" = ? )';
ok $sq<sql>.index('( ( "self"."b" = ? ) OR ( "self"."b" = ? ) )'), 'Found matching b = [500|400]';
ok $sq<sql>.index('( "self"."d" = ? )'), 'Found matching d = 8';
ok $sq<sql>.index('( "self"."a" = ? )'), 'Inherited a = 5';
ok $sq<sql>.index('( "self"."c" = ? )'), 'Inherited c = 6';


is-deeply $sq<params>.sort, [1, 500, 400, 5, 8, 6].sort, 'should be 5 params [1, 500, 400, 5, 8, 6]';

$sq = $d;
ok $sq<sql> eq 'SELECT * FROM "dummy" as self ORDER BY a DESC, b ASC', "order-by in options affects sql";

$s = DB::Xoos::SQL.new(quote => (:placeholder<$>));
$sq = $s.sql-select('a' => 1);
ok $sq<sql> eq 'SELECT * FROM "dummy" as self WHERE "self"."a" = $1', '$ placeholder is OK';
ok $sq<params> == 1, 'and param is correct';


# vi:syntax=perl6
