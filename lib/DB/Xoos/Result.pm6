use DB::Xoos::SQL;
unit role DB::Xoos::Result does DB::Xoos::SQL;

has Bool $!inflate = True;
has %!options = {};
has %!filter  = {};

multi submethod TWEAK (Bool :$!inflate = True, :%!options = {}, :%!filter = {}) {
  die "No driver set (GOT:{(self.?driver//Nil).^name})"
    unless self.?driver;
  my $searchable = "DB::Xoos::{self.driver}::Result";
  my $req = (try require ::($searchable)) === Nil;
  if $req {
    $searchable = "{self.driver}::Result";
    $req = (try require ::($searchable)) === Nil;
  }
  die "Unable to find DB::Xoos::{self.driver}::Result or $searchable or there was a problem loading it"
    if $req;
  require ::($searchable);
  self does ::($searchable) unless self ~~ ::($searchable);

  callsame;
}

method filter  { %!filter;  }
method options { %!options; }
multi method inflate { $!inflate; }

method set-filter(%filter)   { %!filter = %filter;   self; }
method set-options(%options) { %!options = %options; self; }
method set-inflate($inflate) { $!inflate = $inflate; self; }
