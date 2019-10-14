use DB::Xoos::Role::DynamicLoader;
use DB::Xoos;
use lib 't/lib';
use Row1;
use Test;

plan 3;

subtest {
  my class TestDL does DB::Xoos::Role::DynamicLoader {
    multi method connect(Any:D :$db, :%options?, *%_) { '' }
    multi method connect(Str:D $dsn, :%options?, *%_) { '' }
    method db { 'x'; }
    method test1 {
      my $model = self!from-structure({
        name => 'test1',
        row-class => 'Row1',
      });
      ok $model.row ~~ Row1, 'uses custom row OK';

      $model = self!from-structure({
        name => 'test1',
        columns => {
          id  => { :type<integer>, :nullable(False), :is-primary-key, :auto-increment },
          pid => { :type<integer>, :nullable(True), },
        },
      });
      ok $model.row.^name eq 'Row::Test1', 'auto generated row class';
      ok $model.columns.elems == 2, 'column count is correct';
      ok $model.relations.elems == 0, 'row count is zeroed';

      $model = self!from-structure({
        name => 'test23',
        columns => {
          id  => { :type<integer>, :nullable(False), :is-primary-key, :auto-increment },
        },
        relations => {
          test => { :type<str> }, # not a valid relationship
        },
      });
      ok $model.row.^name eq 'Row::Test23', 'auto generated row class';
      ok $model.columns.elems == 1, 'column count is correct';
      ok $model.relations.elems == 1, 'row count is zeroed';
    }
  };

  TestDL.new.test1;
}, 'Dynamic loader from structure';

subtest {
  my class TestDL does DB::Xoos {
    multi method connect(Any:D :$!db, :%options?) { $!db = 'test'; }
    multi method connect(Str:D $dsn, :%options?) { $!db = 'test'; }
  };
  my $test = TestDL.new(:prefix(''));
  $test.connect('');
  $test.model('M1');
  ok $test.loaded-models.elems == 1, 'loaded M1';
  ok $test.model('M1').XX == 42, 'XX callable on model';
  ok $test.model('M1').row.^name eq 'Row::M1', 'Loaded correct row class (GOT:'~$test.model('M1').row.^name~')';
  ok $test.model('M1').row.XX == 42, 'Row can access model';
  is $test.model('M1').db, 'test', 'Test model gets correct db';
  $test.model('R1');
  ok $test.model('R1').row.^name ~~ /'anon'/, 'R1 has anonymous class';
  ok $test.loaded-models.elems == 2, 'R1 & M1 still cached';
}, 'Dynamic loader with files';

try require ::('YAML::Parser::LibYAML');
subtest {
  if ::('YAML::Parser::LibYAML') !~~ Failure {
    my class TestDL does DB::Xoos {
      multi method connect(Any:D :$!db, :%options) { '' }
      multi method connect(Str:D $dsn, :%options) { '' }
    };
    my $test = TestDL.new;
    $test.load-models(['t/models']);
    ok $test.loaded-models.elems == 2, 'loaded two yaml models';
    ok $test.loaded-models.sort ~~ qw<Customer Order>, 'Have Customer and Order models';
    ok $test.model('Customer').columns.elems == 4, 'Customer has proper number of columns';
    ok $test.model('Customer').relations.elems == 3, 'Customer has proper number of relations';
    ok $test.model('Order').columns.elems == 4, 'Order has proper number of columns';
    ok $test.model('Order').relations.elems == 1, 'Order has proper number of relations';
  } else {
    ok True, 'Not testing YAML, need YAML::Parser::LibYAML';
  }
}, 'Testing YAML file loading';
