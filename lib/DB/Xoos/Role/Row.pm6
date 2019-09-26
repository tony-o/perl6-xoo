unit role DB::Xoos::Role::Row;

has $!model;

submethod BUILD(:$!model) { };

method model { $!model; };
