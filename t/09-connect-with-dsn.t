#!/usr/bin/env perl6

use lib 'lib';
use lib 't/lib';
use DB::Xoos;
use DB::Xoos::DSN;
use Test;

plan 2;

my $cwd = $*CWD;
$*CWD = 't'.IO;

my DB::Xoos $d .=new(
  :dsn('d://test.sqlite3'),
  :options({ :prefix<X> })
);

ok True, 'connected to test.sqlite3 OK';

is $d.loaded-models.elems, 4, 'loaded all of the test models fine';

$*CWD = $cwd;
