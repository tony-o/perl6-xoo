use DB::Xoos::Type;
use X::DB::Exception;
unit class DB::Xoos::Type::Bool is DB::Xoos::Type;

has $!value;

submethod BUILD (:$!value, :$nullable) {
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
      $!value = $new-value.so;
    },
  ;
}

method !test($val --> Bool) {
  return False unless self.test($val);
  return True if $val ~~ Bool;
  return True if $val !~~ Bool && $val.^can('so');
  return True if Any ~~ $val && self.is-nullable;
  False;
}
