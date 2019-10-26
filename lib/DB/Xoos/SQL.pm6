unit role DB::Xoos::SQL;

has $.quote;

submethod BUILD(:%quote) {
  $!quote = %({ :identifier<`>, :value<">, :placeholder<?> }, %quote);
}

method sql-select(%filter?, %options?) {
  self!sql(:%filter, :%options);
}

method sql-insert(%values) {
  self!sql(:insert, :update-values(%values));
}

method sql-update(%filter, %options, %values) {
  self!sql(:update, :update-values(%values), :%filter, :%options);
}

method sql-delete(%filter?, %options?) {
  self!sql(:delete, :%filter, :%options);
}

method sql-count(%filter?, %options?) {
  self!sql(:%filter, :%options, :field-override('count(*) cnt'));
}

method !sql($page-start?, $page-size?, :$field-override = Nil, :$update = False, :%update-values?, :$delete = False, :$insert = False, :%filter = { }, :%options = { }) {
  my (@*params, $sql);

  if $update {
    $sql  = 'UPDATE ';
    $sql ~= self!gen-table(:for-update);
    $sql ~= self!gen-update-values(%update-values);
    $sql ~= self!gen-filters(key-table => self.table-name, :%filter) if %filter.keys;
  } elsif $delete {
    $sql  = 'DELETE FROM ';
    $sql ~= self!gen-table(:for-update);
    $sql ~= self!gen-filters(key-table => self.table-name, :%filter) if %filter.keys;
  } elsif $insert {
    $sql  = 'INSERT INTO ';
    $sql ~= self!gen-table(:for-update);
    $sql ~= ' ('~self!gen-field-ins(%update-values)~') ';
    $sql ~= 'VALUES (' ~ (
      ($!quote<placeholder>//'?') eq '$'
        ?? (1..@*params.elems).map({ '$' ~ $_ }).join(', ')
        !! (($!quote<placeholder>//'?') x @*params.elems).split('', :skip-empty).join(', ')
    ) ~ ')';
  } else {
    $sql = 'SELECT ';
    if $field-override {
      $sql ~= "$field-override ";
    } else {
      $sql   ~= self!gen-field-sels(:%options)~' ';
    }
    $sql   ~= self!gen-table;
    $sql   ~= self!gen-joins(:%options);
    $sql   ~= self!gen-filters(:%filter) if %filter.keys;
    $sql   ~= self!gen-order(:%options) if %options.keys;
  }

  { sql => $sql, params => @*params };
}

method !gen-update-values(%values) {
  ' SET '~%values.keys.map({ self!gen-quote($_, :table(''))~' = '~self!gen-quote(%values{$_})}).join(', ');
}

method !gen-field-sels(:%options = { }) {
  %options<fields>.defined && %options<fields>.keys
    ?? %options<fields>.map({ self!gen-id($_) }).join(', ')
    !! '*';
}

method !gen-field-ins(%values) {
  my @cols;
  for %values -> $col {
    my ($key, $val) = $col.kv;
    @cols.push(self!gen-id($key));
    @*params.push($val);
  }
  @cols.join(', ');
}

method !gen-table(:$for-update = False) {
  ($for-update??''!!'FROM ')~(self.^can('table-name')
    ?? self!gen-id(self.table-name)~($for-update??''!!' as self')
    !! self!gen-id('dummy')~($for-update??''!!' as self'));
}

method !gen-quote(\val, $force = False, :$table) {
  if !$force && val =:= try val."{val.^name}"() {
    # not a container
    return self!gen-id(val, :$table);
  } else {
    push @*params, val;
    return self!placeholder;
  }
}

method !placeholder {
  my $ph = $!quote<placeholder> // '?';
  if $ph eq '$' {
    return '$' ~ @*params.elems;
  }
  $ph;
}

method !gen-id($value,:$table?) {
  my $qc = MY::<$!quote><identifier> // '"';
  my $sc = MY::<$!quote><separator>  // '.';
  my @s  = $value.split($sc);
  @s.prepend($table)
    if $table.defined && $table ne '' && @s.elems == 1;
  "{$qc}{@s.join($qc~$sc~$qc)}{$qc}";
}

method !gen-pairs($kv, $type = 'AND', $force-placeholder = False, :$key-table?, :$val-table?) {
  my @pairs;
  if $kv ~~ Pair {
    my ($eq, $val);
    if $kv.key ~~ Str && $kv.key eq ('-or'|'-and') {
      @pairs.push: self!gen-pairs($kv.value, $kv.key.uc.substr(1), $force-placeholder, :$key-table, :$val-table)~' )';
      $eq := 'andor';
    } elsif $kv.value ~~ Hash {
      $eq  := $kv.value.keys[0];
      $val := $kv.value.values[0];
    } elsif $kv.value ~~ Block && $kv.value.().elems == 2 {
      $eq  := $kv.value.()[0];
      $val := $kv.value.()[1];
    } elsif $kv.value ~~ Array {
      my @arg;
      for @($kv.value) -> $x {
        @arg.push( self!gen-quote($x, $force-placeholder) );
      }
      $eq  := 'in';
      @pairs.push: self!gen-id($kv.key, :table($key-table))~" $eq ("~@arg.join(', ')~")";
    } else {
      $eq  := '=';
      $val := $kv.value
    }
    @pairs.push: self!gen-id($kv.key, :table($key-table))~" $eq "~self!gen-quote($val, $force-placeholder, :table($val-table))
      if $eq ne ('andor'|'in');
  } elsif $kv ~~ Hash {
    for %($kv).pairs -> $x {
      @pairs.push: '( '~self!gen-pairs($x.key eq ('-or'|'-and') ?? $x.value !! $x, $x.key eq ('-or'|'-and') ?? $x.key.uc.substr(1) !! $type, $force-placeholder, :$key-table, :$val-table)~' )';
    }
  } elsif $kv ~~ Array {
    my $arg;
    for @($kv) -> $x {
      $arg = $x.WHAT ~~ List ?? $x.pairs[0].value !! $x;
      @pairs.push: '( '~self!gen-pairs($arg, $type, $force-placeholder, :$key-table, :$val-table)~' )';
    }
  }
  @pairs.join(" $type ");
}

method !gen-filters(:$key-table = 'self', :%filter) {
  ' WHERE '~self!gen-pairs(%filter, 'AND', True, :$key-table);
}

method !gen-join-str(Hash $attr where { $_<table>.defined && $_<on>.defined }) {
  my $join = ' ';
  $join   ~= $attr<type> ?? $attr<type> !! 'left outer';
  $join   ~= ' join ';
  $join   ~= self!gen-id($attr<table>);
  $join   ~= ' as '~$attr<as>
    if $attr<as>.defined;
  $join   ~= ' on ';
  $join   ~= self!gen-pairs($attr<on>, :key-table($attr<as>//$attr<table>), :val-table<self>);
  $join;
}

method !gen-order(:%options = { }) {
  my @pairs;
  if %options<order-by>.defined {
    for @(%options<order-by>) -> $order {
      @pairs.push(
        $order ~~ Pair
          ?? $order.key ~ ' ' ~ $order.value.uc
          !! "$order ASC"
      );
    }
  }
  @pairs.elems == 0 ?? '' !! ' ORDER BY ' ~ join(', ', @pairs);
}

method !gen-joins(:%options) {
  my $joins = '';
  if %options<join>.defined {
    if %options<join> ~~ Array {
      for %options<join>.values -> %x {
        $joins ~= self!gen-join-str(%x);
      }
    }
    $joins ~= self!gen-join-str(%options<join>) if %options<join> ~~ Associative;
  }
  $joins;
}
