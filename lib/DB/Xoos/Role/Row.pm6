unit role DB::Xoos::Role::Row;

has $!model;
has %!field-data;
has $!is-dirty;
has %!field-changes;
has @!columns;
has @!relations;
has $!db;

multi submethod BUILD(:$!model, :%field-data, :%!field-changes?, :$!is-dirty = True, :$!db, *%_) {
  @!columns = |$!model.columns if $!model.^can('columns');
  my %fd    = (%field-data//{}).clone;
  for @!columns -> $col {
    my ($key, $spec)      = $col.kv;
    %!field-data{$key}    = %fd{$key}//Nil; #TODO type check
    %!field-changes{$key} = %!field-data{$key}
      if $!is-dirty;
    %fd{$key}:delete;
    self.^add_method("$key", method ($value?) {
      if $value.defined {
        return self.set-column($key, $value);
      }
      self.get-column($key);
    }) unless self.^can($key);
  }

  @!relations = |$!model.relations if $!model.^can('relations');
  for @!relations -> $rel {
    my ($key, $spec) = $rel.kv;
    self.^add_method($key, method {
      self.get-relation($key, :spec($spec));
    }) unless self.^can($key);
  }

  warn 'Erroneous field data provided to row ('~self.^name~'), either the model definition is incorrect or something is passing bad data (keys: '~%fd.keys.join(', ')~')'
    if %fd.keys.elems;
};

method model { $!model; };
method set-column(Str $key, $value) {
  my $field-info = @!columns.grep({ $_.key eq $key })[0].value;
  die "Cannot find field {$key}" unless defined $field-info;
  my $new-value = $value;
  if $field-info<validate>//Nil ~~ Callable {
    die "Field $key did not pass validation with value ($new-value)"
      unless $field-info<validate>($new-value);
  }
  %!field-changes{$key} = $new-value;
  $!is-dirty = True;
}

method set-columns(*%values) {
  for %values {
    my ($key, $value) = $_.kv;
    self.set-column($key, $value);
  }
}

method get-column(Str $key) {
  %!field-changes{$key} // %!field-data{$key} // Nil;
}

method get-relation(Str $column, :%spec?) {
  my %meta = %spec//Nil;
  if !%meta {
    %meta = @!relations.map({ $_.key eq $column })[0].value//();
  }
  die "No relationship ($column) found in model ({$!model.^name})"
    if !%meta;
  my %filter;
  for %meta<relate>.List -> $r {
    if $r.key.substr(0,1) eq '+' {
      %filter{$r.key.substr(1)} = $($r.value);
    } else {
      %filter{$r.value} = %!field-data{$r.key};
    }
  }
  my $query = self.dbo.model(%meta<model>).search(%filter);
  return $query.first
    if %meta<has-one> && $query.count;
  $query;
}
method columns {@!columns;}
method field-changes {%!field-changes;}
method field-data {%!field-data;}
method is-dirty(Bool $!is-dirty = $!is-dirty) {$!is-dirty;}
