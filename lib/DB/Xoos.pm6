use DB::Xoos::Role::DynamicLoader;
unit role DB::Xoos does DB::Xoos::Role::DynamicLoader;

has $.db;
has $!prefix = '';

#multi submethod BUILD(:$!prefix, :$!db) { }

multi method connect(Any:D :$!db, :%options?) {...}
multi method connect(Str:D $dsn, :%options?) {...}

method model(Str $model-name, Str :$module?) {
  if self!get-cache($model-name).defined {
    return self!get-cache($model-name).clone;
  }
  my $prefix = $!prefix // try { $?OUTER::CLASS.^name; } // '';
  my $model  = $module.defined ?? $module !! "{$prefix ne '' ?? "$prefix\::" !! ''}Model\::$model-name";
  my $row    = $model.subst('::Model::', '::Row::');
  my $loaded = (try require ::("$model")) === Nil;
  unless $loaded {
    warn "Unable to load model: $model-name ($model)\n";
    return Nil;
  }
  $row .=subst(/^'Model::'/, 'Row::');
  $model = (require ::("$model")).new(db => $!db);
  try require ::($row);
  if ::($row) ~~ Failure {
    $row = (class :: does DB::Xoos::Role::Row { }).new(:$model, :$!db);
  } else {
    $row = ::($row).new(:$model, :$!db);
  }
  $model.set-row-class($row) if $model.row ~~ Nil;
  self!set-cache($model-name, $model);
  self!get-cache($model-name).clone;
}

method loaded-models { self!get-cache-keys; }
method db { $!db; }
method prefix { $!prefix//''; }
