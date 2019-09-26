use DB::Xoos::Role::Row;

unit class Row1 does DB::Xoos::Role::Row;

method hello {
  5..10.pick;
}
