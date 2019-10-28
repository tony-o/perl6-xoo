use X::DB::Exception;
use Test;


my @types   = 'DB::Xoos::Type::Int+1', 'DB::Xoos::Type::Int+2', 'DB::Xoos::Type::VarChar+1', 'DB::Xoos::Type::VarChar+2', 'DB::Xoos::Type::JSON', 'DB::Xoos::Type::Bool';
my %args    = (
  'DB::Xoos::Type::Int+2'  => { :!nullable, :!signed, :value(5) },
  'DB::Xoos::Type::VarChar+1' => { :length(17) },
  'DB::Xoos::Type::VarChar+2' => { :!nullable, :value('XYZ'), :strict, :length(200) },
  'DB::Xoos::Type::Bool'   => { :!nullable, :value(True) },
);
my %success = ( 
  'DB::Xoos::Type::Int+1' => [
    5    => 5,
    15   => 15,
    -5   => -5,
    0    => 0,
    '5'  => 5,
    '15' => 15,
    '-5' => -5,
    '0'  => 0,
    Pair.new(Any, Any),
  ],
  'DB::Xoos::Type::Int+2' => [
    5    => 5,
    15   => 15,
    0    => 0,
    '5'  => 5,
    '15' => 15,
    '0'  => 0,
    -0   => 0,
    '-0' => 0,
  ],
  'DB::Xoos::Type::VarChar+1' => [ 5 => '5', '15' => '15', 'VarChar' => 'VarChar', Pair.new(Any, Any), X::AdHoc.new(:message("hi")) => 'Unexplained error' ],
  'DB::Xoos::Type::VarChar+2' => [ '5' => '5', '15' => '15', 'VarChar' => 'VarChar', ],
  'DB::Xoos::Type::JSON'  => [
    '{ }'        => { },
    '{ "a": 5 }' => { :a(5) },
    '[ ]'        => [ ],
    Pair.new(Any, Any),
  ],
  'DB::Xoos::Type::Bool' => [
    Pair.new(True, True),
    Pair.new(False, False),
    1    => True,
    0    => False,
    42   => True,
    ''   => False,
    'A+' => True,
  ],
);

my %dies    = (
  'DB::Xoos::Type::Int+1'  => ['VarChar', '15.5', '-15.5'],
  'DB::Xoos::Type::Int+2'  => ['VarChar', '15.5', '-15.5', -5, Any],
  'DB::Xoos::Type::VarChar+1' => ['I am too large for a column with 17 characters' => X::DB::Exception::ValueTooLarge],
  'DB::Xoos::Type::VarChar+2' => [5, -5, X::AdHoc.new(:message("hi")), Any, ('x' x 201) => X::DB::Exception::ValueTooLarge ],
  'DB::Xoos::Type::JSON'   => ['{', '}', '{ a }', '{ "a" }',],
  'DB::Xoos::Type::Bool'   => [Any],
);

plan +@types;

subtest {
  my $key  = "$_";
  my $type = $key.split('+')[0];
  my %cnst = %args{$key} // ();
  require ::($type);
  my $a = ::($type).new(|%cnst);
  my ($kerr, $verr);
  is (%cnst<value>//Any), $a.value, 'should be undefined before setting';
  for |(%success{$key}//[]) -> $pair {
    $a.value = $pair.key;
    try {
      CATCH { when X::DB::Exception::TypeConflict {
        ok False, 'Assignment of ' ~ $pair.key.gist ~ ' failed';
      } }
      is $a.value, $pair.value, 'assignment success ('~$pair.key.gist~')';
    };
  }
  for |(%dies{$key}//[]) -> $val {
    $verr = X::DB::Exception::TypeConflict;
    $kerr = $val;
    if $val ~~ Pair {
      $verr = $val.value;
      $kerr = $val.key;
    }
    try {
      CATCH {
        default {
          is $_.WHAT, $verr, $key ~ ' exception type (expecting: ' ~ $verr.WHAT.^name ~ ')';
        }
      }
      $a.value = $kerr;
      ok False, 'should die on assignment ('~$val.gist~')';
    }
  }
}, $_ for @types;
