use DB::Xoos::Type;
use X::DB::Exception;
unit class DB::Xoos::Type::JSON is DB::Xoos::Type;

has $!value;
has $!strict;

submethod BUILD (:$!value, :$nullable, :$!strict = False) {
  callsame;
  self!error($!value) if !self.is-nullable && Any ~~ $!value;
}

method !error($value) {
  die X::DB::Exception::TypeConflict.new(
    :type(self.^name),
    :value($value),
  ) unless self!test($value);
}

method value is rw {
  Proxy.new:
    FETCH => -> $ { $!value; },
    STORE => -> $, $new-value {
      self!error($new-value);
      $!value := $new-value ~~ (Hash|Array) ?? $new-value !! $new-value.defined ?? self!convert($new-value) !! Any;
    },
  ;
}

method !test($val --> Bool) {
  return True if Any ~~ $val && self.is-nullable;
  return True if $val ~~ (Hash|Array);
  return True if self!convert($val) !~~ X::DB::Exception::JSONParse;
  False;
}

try require ::('JSON::Fast');
method !convert(Str() $val) {
  state $converter = try {
    CATCH { default {
      warn 'Please install JSON::Fast for better processing';
      &Rakudo::Internals::JSON::from-json;
    } }
    ::('&JSON::Fast::from-json');
  };
  my $rval;
  try {
    CATCH { default { $rval := X::DB::Exception::JSONParse.new; } }
    $rval := $converter($val);
  };
  $rval;
}
