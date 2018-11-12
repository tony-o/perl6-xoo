use DB::Xoos;
unit class DB::Xoos::Oracle does DB::Xoos;

use DB::Xoos::DSN;
use DBIish;

multi method connect(Any:D: :$db, :%options) {
  $!db     = $db;
  $!driver = 'Oracle';
  $!prefix = %options<prefix> // '';
  self.load-models(%options<model-dirs>//[]);
}

multi method connect(Str:D $dsn, :%options) {
  my %connect-params = parse-dsn($dsn);

  die 'unable to parse DSN' ~ $dsn unless %connect-params.elems;
  my $db;
 
  if %connect-params<host> ne '' {
    $db = DBIish.connect('oracle', database => %connect-params<host>, |(:%options<db>//{}));
  } else {
    $db = DBIish.connect('oracle', |(:%options<db>//{}));
  }

  self.connect(
    :$db,
    :%options,
  );
}
