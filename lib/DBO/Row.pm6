unit role DBO::Row;

has $!table-name;
has $!db;
has $.quote;
has $!driver;
has %!field-data;
has $!model;
has %!field-changes;
has @!columns;
has @!relations;
has $!is-dirty;
has $!dbo;

submethod BUILD (:$!driver, :$!db, :$!quote, :%field-data, :$!model, :$!is-dirty = True, :$!dbo) {
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

  @!relations = $!model.relations;
  for @!relations -> $rel {
    my ($key, $spec) = $rel.kv;
    self.^add_method($key, method {
      self.get-relation($key, :spec($spec));
    }) unless self.^can($key);
  }
  warn 'Erroneous field data provided to row, either the model definition is incorrect or something is passing bad data (keys: '~%fd.keys.join(', ')~')'
    if %fd.keys.elems;

}

method table-name { $!table-name; }
method db         { $!db; }
method dbo        { $!dbo; }
method driver     { $!driver; }
method model      { $!model; }
method is-dirty   { $!is-dirty; }

method set-column(Str $key, $value) {
  %!field-changes{$key} = $value;
  #TODO: ensure column exists, validation hooks, etc
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
  %filter.perl.say;
  self.dbo.model(%meta<model>).search(%filter);
}

method update {
  my @keys = @!columns.grep({ $_.value<is-key> || $_.value<is-primary-key> });
  #find out if key exists
  my %filter;
  @keys.map({ my $value = %!field-changes{$_.key}//%!field-data{$_.key}; %filter{$_.key} = $value if $value; });
  if %filter.keys.elems != @keys.elems {
    #create
    my %field-data = @!columns.map({
      my $x = $_.key;
      $x => (%!field-changes{$x}//%!field-data{$x}//Nil)
        if @keys.grep({ $_.key ne $x })
    });
    my $new-id = $!model.insert(%field-data);
    my $key    = @keys.grep({$_.value<is-primary-key>})[0].key // Nil;
    %!field-data{$key} = $new-id
      if $key;
  } elsif $!model.search(%filter).count == 1 {
    #update
    $!model.search(%filter).update(%!field-changes);
  } else {
    %filter.perl.say;
    die 'More than one row found for key.';
  }
  #TODO refresh %!field-data
  for %!field-changes -> $f {
    %!field-data{$f.key} = $f.value
      if !(@keys.grep({ $_.key eq $f.key })[0].value<is-primary-key>//False);
  }
  %!field-changes = ();
  $!is-dirty = False;
}
