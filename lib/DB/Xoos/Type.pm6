unit role DB::Xoos::Type;

has Bool $!nullable;

submethod BUILD(Bool :$!nullable = True) { }

method test ($value --> Bool) {
  return True if $!nullable;
  return False if !$!nullable && Any ~~ $value.WHAT;
  True;
}

method is-nullable(--> Bool) { $!nullable; }
