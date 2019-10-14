unit module DB::Xoos::DSN;

#use Grammar::Tracer::Compact;
grammar dsn {
  token TOP {
    ^
      <driver> '://' <auth>? <host> <port> <db-name>
    $
  }

  regex driver {
    \w+
  }

  token auth {
    <user> (
      | ':' <pass> ** 0..1
      | ':' ** 0..1
    ) '@'
  }

  token user {
    <-[:@]>+
  }

  regex pass {
    <-[@]>*
  }

  regex host {
    [ \w | \d | '.' | '_' | '-' ]*
  }

  regex port {
     ':' <num>
   | ''
  }

  regex num { \d+ }

  regex db-name {
      '/' <db>
    | ''
  }

  regex db { .+ }
};

sub default-ports (Str:D $driver) {
  return 3306 if $driver eq 'mysql';
  return 5432 if $driver eq ('pg'|'postgresql');
  return Nil  if $driver eq 'sqlite';
  return Nil;
}

sub parse-dsn (Str:D $dsn) is export {
  my $parsed = dsn.parse($dsn);

  return Nil unless $parsed ~~ dsn;
  {
    driver => $parsed<driver>.Str,
    user   => $parsed<auth> ?? $parsed<auth><user>.Str !! Nil,
    pass   => $parsed<auth>[0] ?? ($parsed<auth>[0].Str||' ').substr(1) !! Nil,
    host   => $parsed<host>.Str,
    port   => $parsed<port> && $parsed<port><num> ?? $parsed<port><num>.Int !! default-ports(($parsed<driver>//'').Str),
    db     => $parsed<db-name> && $parsed<db-name><db> ?? $parsed<db-name><db>.Str !! Nil,
  };
}