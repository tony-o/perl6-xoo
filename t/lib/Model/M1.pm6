use DB::Xoos::Role::Model;

unit class Model::M1 does DB::Xoos::Role::Model['m1'];

has @.columns =
   id => {
    type => 'integer',
    nullable => False,
    :is-primary-key,
    :auto-increment,
  },
  pid => {
    :type<integer>,
    :!nullable,
  }
;


method XX { 42; }
