use DB::Xoos::Role::DynamicLoader;
use DB::Xoos::Role::Row;
use DB::Xoos::Role::Model;
unit role DB::Xoos[:$model = DB::Xoos::Role::Model, :$row = DB::Xoos::Role::Row] does DB::Xoos::Role::DynamicLoader;

has $.db;
has $!prefix = '';

multi method connect(Any:D :$!db, :%options?) {...}
multi method connect(Str:D $dsn, :%options?) {...}

method parameterized-row { $row; }
method parameterized-model { $model; }

method model(Str $model-name, Str :$module?) {
  if self!get-cache($model-name).defined {
    return self!get-cache($model-name).clone;
  }
  my $prefix = $!prefix // try { $?OUTER::CLASS.^name; } // '';
  my $modeln = $module.defined ?? $module !! "{$prefix ne '' ?? "$prefix\::" !! ''}Model\::$model-name";
  my $rown   = $modeln.subst('::Model::', '::Row::');
  my $loaded = (try require ::("$modeln")) === Nil;
  unless $loaded {
    warn "Unable to load model: $model-name ($modeln)\n";
    return Nil;
  }
  $modeln = (require ::("$modeln")).new(db => $!db);
  unless $modeln.row {
    $rown .=subst(/^'Model::'/, 'Row::');
    $loaded = (try require ::($rown)) === Nil;
    if $loaded {
      $rown = Metamodel::ClassHOW.new_type(:name($modeln.^name.Str.subst('Model', 'Row')));
      $rown.^add_role($row);
      $rown.^compose;
      $rown .=new(:$modeln, :$!db);
    } else {
      $rown = (require ::($rown)).new(:$modeln, :$!db);
    }
    $modeln.set-row-class($rown.new(:model($modeln))) if $modeln.row ~~ Nil;
  }
  $modeln does $model unless $modeln ~~ $model;
  self!set-cache($model-name, $modeln);
  self!get-cache($model-name).clone;
}

method loaded-models { self!get-cache-keys; }
method db { $!db; }
method prefix { $!prefix//''; }
