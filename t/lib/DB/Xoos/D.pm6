use DB::SQLite;

class DB::Xoos::D {
  method get-db(%params, :%options) {
    my $conn = DB::SQLite.new(filename => ($*BASE-DIR//'.'.IO).add(%params<host>).resolve.absolute);
    $conn;
  }
}
