unit role DB::Xoos::Role::Cache;

has %!cache;

method !set-cache($key, $value, Bool :$overwrite = False --> Bool) {
  return False if %!cache{$key} && !$overwrite;
  %!cache{$key} := $value;
  return True;
}

method !get-cache($key) {
  %!cache{$key} // Nil;
}

method !get-cache-keys { %!cache.keys; }
