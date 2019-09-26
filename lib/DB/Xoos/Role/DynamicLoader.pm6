use DB::Xoos::Role::Model;
use DB::Xoos::Role::Row;
use DB::Xoos::Role::Cache;
unit role DB::Xoos::Role::DynamicLoader does DB::Xoos::Role::Cache;

method !from-structure($mod) {
  my $name = $mod<name>//$mod<table>;
  my @model-attributes;
  my $row-class;
  
  @model-attributes.push($mod<name>.lc) unless $mod<table>;
  @model-attributes.push($mod<table>) if $mod<table>;
  try {
    CATCH {
      default {
        $row-class = Metamodel::ClassHOW.new_type(:name("{self.^can('prefix') ?? "{self.prefix}\:\:" !! ""}Row::{$name.tc}"));
        $row-class.^add_role(DB::Xoos::Role::Row);
        $row-class.HOW.compose($row-class);
        @model-attributes.push($row-class);
      }
    }
    die '' unless $mod<row-class>;
    require ::($mod<row-class>.Str);
    $row-class = ::($mod<row-class>.Str); 
    @model-attributes.push($row-class);
  };

  my $model-class := Metamodel::ClassHOW.new_type(:name('DB::Xoos::Model::'~$name));
  $model-class.^add_role(DB::Xoos::Role::Model[|@model-attributes]);
  try $model-class.HOW.add_attribute($model-class, Attribute.new(
    :name<@.columns>, :has_accessor(1), :type(Array), :package($model-class.WHAT),
  ));
  try $model-class.HOW.add_attribute($model-class, Attribute.new(
    :name<@.relations>, :has_accessor(1), :type(Array), :package($model-class.WHAT),
  ));
  $model-class.HOW.compose($model-class);
  my $model = $model-class.new(
    columns => [ $mod<columns>.keys.map({
      $_ => $mod<columns>{$_}
    }) ],
    relations => [ $mod<relations>.keys.map({
      $_ => $mod<relations>{$_}
    }) ],
  );

  self!set-cache($name, $model);

  $model;
}

method load-models(@model-dirs?, :%dynamic?) {
  my $base = (self.^can('prefix') && self.prefix) // try { $?CALLER::CLASS.^name } // '';
  my @possible = try {
    CATCH { default { .say unless @model-dirs.elems; } }
    "lib/{$base eq '' ?? '' !! ($base.subst('::', '/') ~ '/')}Model".IO.dir.grep(
      * ~~ :f && *.extension eq 'pm6'
    ) if "lib/{$base eq '' ?? '' !! ($base.subst('::', '/') ~ '/')}Model".IO ~~ :d;
  };

  for @possible -> $f {
    next unless $f.index("lib/$base") !~~ Nil;
    my $mod-name = $f.path.substr($f.index("lib/$base")+4, $f.rindex('.') - $f.index("lib/$base") - 4);
    $mod-name .=subst(/^^(\/|\\)/, '');
    $mod-name .=subst(/(\/|\\)/, '::', :g);
    try {
      CATCH { default {
        warn "Error loading: $mod-name\n" ~ $_.Str;
      } }
      require ::($mod-name);
      next unless ::($mod-name) ~~ DB::Xoos::Role::Model;
      self!set-cache($mod-name.split('::')[*-1], ::($mod-name).new)
    }
  }
  if @model-dirs.elems {
    my $no-yaml = (try require ::('YAML::Parser::LibYAML')) === Nil;
    warn 'Cannot find YAML::Parser::LibYAML when attempting to load yaml models'
      if $no-yaml;
    unless $no-yaml {
      my $parser = ::('YAML::Parser::LibYAML::EXPORT::DEFAULT::&yaml-parse');
      for @model-dirs -> $dir {
        my @files = $dir.IO.dir;
        for @files -> $fil {
          next if $fil !~~ :f || $fil.extension ne 'yaml';
          my $mod = $parser.($fil.relative);
          self!from-structure($mod);
        }
      }
    }
  }
  self!from-structure($_) for %dynamic.values;
}
