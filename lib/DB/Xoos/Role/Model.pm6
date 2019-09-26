unit role DB::Xoos::Role::Model[$table-name, $row-class?];

has $!row;

submethod TWEAK(|) {
  if $row-class ~~ Str {
    $!row = ::($row-class).new(:model(self));
  } elsif Any !~~ $row-class {
    $!row = $row-class.new(:model(self));
  }
}

method row {
  $!row ?? $!row !! Nil;
}

method set-row-class($row) {
  $!row = $row;
}
