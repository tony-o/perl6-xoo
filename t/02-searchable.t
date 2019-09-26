use DB::Xoos::Role::Searchable;
use Test;

plan 1;

subtest {
  my class XX does DB::Xoos::Role::Searchable {
    method search { };
    method first { ''; }
    method last { ''; }
    method all { ''; }
    method insert { ''; }
    method next { ''; }
    method count { ''; }
    method update { ''; }
    method delete { ''; }
    method sql( --> Str) { ''; }
  };
  ok XX.new.sql eq '', 'Composes OK';
}, 'Can extend DB::Xoos::Role::Searchable';
