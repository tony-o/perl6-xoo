use DB::Xoos::Type;
use X::DB::Exception;
unit class DB::Xoos::Type::VarChar is DB::Xoos::Type;

has $!value;
has $!strict;
has $!length;

submethod BUILD (:$!value, :$nullable, :$!strict = False, Int:D :$!length) {
  die X::DB::Exception::Generic(:message('Refusing to create a char column with size zero'))
    unless $!length > 0;
  callsame;
  self!error($!value) if !self.is-nullable && Any ~~ $!value;
}

method !error($value) {
  die X::DB::Exception::TypeConflict.new(
    :type(self.^name),
    :value($value),
  ) unless self!test($value);
  die X::DB::Exception::ValueTooLarge.new(
    :type(self.^name),
    :value($value),
    :size($!length),
  ) if ($value//'').Str.chars > $!length;
}

method value is rw {
  Proxy.new:
    FETCH => -> $ { $!value; },
    STORE => -> $, $new-value {
      self!error($new-value);
      $!value = Any ~~ $new-value ?? Any !! $!strict ?? $new-value !! $new-value.Str;
    },
  ;
}

method !test($val --> Bool) {
  return False unless self.test($val);
  return True if $val ~~ Str;
  return True if $val !~~ Str && $val.^can('Str') && !$!strict;
  return True if Any ~~ $val && self.is-nullable;
  False;
}
