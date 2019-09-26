use DB::Xoos::Role::Model;

unit class Model::R1 does DB::Xoos::Role::Model['r1'];

has @.columns =
   id => {
    type => 'integer',
    nullable => False,
    :is-primary-key,
    :auto-increment,
  }
;


method XX { 84; }
