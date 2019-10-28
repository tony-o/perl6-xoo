use DB::Xoos::Type;
use X::DB::Exception;
unit class DB::Xoos::Type::Int is DB::Xoos::Type;

has $!value;
has Bool $!signed;

submethod BUILD (:$!value, :$nullable, :$!signed = True) {
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
      $!value = try { $new-value.Int } // Nil;
    },
  ;
}

method !test($val --> Bool) {
  return False unless self.test($val);
  return True if $val ~~ Int && ($!signed ?? True !! $val >= 0);
  return True if $val ~~ Str && (
       ($!signed && $val ~~ m/^'-'?\d+$/)
    || (!$!signed && ($val ~~ m/^\d+$/ || $val eq '-0'))
  );
  return True if Any ~~ $val && self.is-nullable;
  False;
}
