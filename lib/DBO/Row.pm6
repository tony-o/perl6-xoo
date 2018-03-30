unit role DBO::Row;

has $!table-name;
has $!db;
has $.quote;
has $!driver;
has %!field-data;
has $!model;
has %!field-changes;
has @!columns;
has $!is-dirty;

submethod BUILD (:$!driver, :$!db, :$!quote, :%field-data, :$!model, :$!is-dirty = True) {
  $!table-name = $!model.table-name;
  $!quote      = $!driver eq 'mysql'
    ?? { identifier => '`', value => '"',  separator => '.' }
    !! { identifier => '"', value => '\'', separator => '.' };
  @!columns = $!model.columns;
  my %fd    = %field-data.clone;
  for @!columns -> $col {
    my ($key, $spec)      = $col.kv;
    %!field-data{$key}    = %fd{$key}//Nil; #TODO type check
    %!field-changes{$key} = %!field-data{$key}
      if $!is-dirty;
    %fd{$key}:delete;
    self.^add_method($key, method ($value?) {
      if $value.defined {
        return self.set-column($key, $value);
      }
      self.get-column($key);
    }) unless self.^can($key);
  }
  warn 'Erroneous field data provided to row, either the model definition is incorrect or something is passing bad data (keys: '~%fd.keys.join(', ')~')'
    if %fd.keys.elems;

}

method table-name { $!table-name; }
method db         { $!db; }
method driver     { $!driver; }
method model      { $!model; }
method is-dirty   { $!is-dirty; }

method set-column(Str $key, $value) {
  %!field-changes{$key} = $value;
  #TODO: ensure column exists, validation hooks, etc
  $!is-dirty = True;
}

method set-columns(Hash $values) {
  for $values.pairs -> ($key, $value) {
    self.set-column($key, $value);
  }
}

method get-column(Str $key) {
  %!field-changes{$key} // %!field-data{$key} // Nil;
}
