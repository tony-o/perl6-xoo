use lib 'lib';
use lib 't/lib';

use DBO;

my $cwd = $*CWD;
$*CWD = 't'.IO;

my DBO $d .=new;
$d.connect(
  driver  => 'Pg',
  options => {
    db     => {
      database => 'tonyo',
    },
    prefix => 'X',
  },
);

my $hello-rs = $d.model('Hello');

my $new-rs = $hello-rs.search({
  a => 1,
});

$new-rs.dump-filter.perl.say;
$new-rs.all;

$*CWD = $cwd;
