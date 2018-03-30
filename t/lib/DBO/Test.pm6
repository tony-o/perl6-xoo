unit module DBO::Test;
use DBIish;

sub configure-sqlite is export {
  my $db = DBIish.connect('SQLite', :database<test.sqlite3>);
  $db.do(q:to/XYZ/);
  DROP TABLE IF EXISTS hello;
  XYZ

  $db.do(q:to/XYZ/);
  CREATE TABLE hello (
    id  INTEGER PRIMARY KEY AUTOINCREMENT,
    txt TEXT
  );
  XYZ

  my $sth = $db.prepare(q:to/XYZ/);
    INSERT INTO hello (txt) VALUES (?);
  XYZ
  $sth.execute('hello world');
  for 0..20 {
    $sth.execute(('a'..'z').roll(10).join);
  }
  $sth.finish;
  $db.dispose;
}
