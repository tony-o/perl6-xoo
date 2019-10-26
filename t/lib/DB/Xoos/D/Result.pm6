use DB::Xoos::Result;
use DB::Xoos::RowInflator;
use DB::Xoos::SQL;
unit role DB::Xoos::D::Result does DB::Xoos::Result does DB::Xoos::SQL does DB::Xoos::RowInflator;

has $!first-next;

method search(%filter?, %options?) {
  my $clone = self.^mro[1].new(
    :driver(self.driver),
    :db(self.db),
    :dbo(self.dbo),
    :columns(self.columns),
    :relations(self.?'relations'()//[]),
  );
  $clone.set-inflate(self.inflate);
  $clone.set-options( %( self.options , %options ) );
  $clone.set-filter( %( self.filter, %filter ) );
  $clone;
}

method all(%filter?, %options?) {
  return self.search(%filter, %options).all
    if %filter.keys || %options.keys;
  my $sql = self.sql-select(self.filter, self.options);
  my @results = self.db.query($sql<sql>, |$sql<params>).hashes.map({
    next unless $_;
    (self.?inflate()//True) && Any !~~ self.?row()
      ?? self.inflate($_)
      !! $_
  });

  @results;
}

method first(%filter?, %options?) {
  return self.search(%filter, %options).first
    if %filter.keys || %options.keys;
  my $sql      = self.sql-select(self.filter, self.options);
  $!first-next = {
    idx  => 0,
    r    => self.db.query($sql<sql>, |$sql<params>).hashes,
  };
  my $data = $!first-next<r>[$!first-next<idx>++] // { };
  return Nil unless $data.keys;
  (self.?inflate//True) && Any !~~ self.?row
    ?? self.inflate($data)
    !! $data;
}

method next(%filter?, %options?) {
  return self.search(%filter, %options).next
    if %filter.keys || %options.keys;
  return self.first
    unless ($!first-next//{}).keys == 2;
  my $data = $!first-next<r>[$!first-next<idx>++] // { };
  return Nil unless $data.keys;
  (self.?inflate//True) && Any !~~ self.?row
    ?? self.inflate($data)
    !! $data;
}

method count(%filter?, %options?) {
  return self.search(%filter, %options).count
    if %filter.keys || %options.keys;
  my $sql = self.sql-count(self.filter);
  self.db.query($sql<sql>, |$sql<params>).hash<cnt>;
}

method update(%values) {
  my $sql = self.sql-update(self.filter, self.options, %values);
  self.db.query($sql<sql>, |$sql<params>);  
}

method delete(%filter?, %options?) {
  return self.search(%filter, %options).delete
    if %filter.keys || %options.keys;
  my $sql = self.sql-delete(self.filter, self.options);
  self.db.query($sql<sql>, |$sql<params>);  
}

method insert(%values) {
  my $sql = self.sql-insert(%values);
  self.db.query($sql<sql>, |$sql<params>);  
  self.db.query('select last_insert_rowid() as nid;').hash<nid>;
}
