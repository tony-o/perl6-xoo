unit role DB::Xoos::RowInflator;

multi method inflate(%data) {
  my $row = self.?row();

  $row.new(
    :field-data(%data),
    :!is-dirty,
    :driver(self.?'driver'() // ''),
    :db(self.?'db'() // Nil),
    :model(self),
    :dbo(self.?'dbo'() // Nil),
  );
}
