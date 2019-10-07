unit role DB::Xoos::Role::Searchable;

has $!filter;
has $!option;

multi submethod BUILD(:$!filter = { }) { }
method !filter {$!filter//{};}
method !option {$!option//{};}
method !set-filter($filter) { $!filter = $filter; }
method !set-option($option) { $!option = $option; }

method search(|) {...}
method first(|) {...}
method all(|) {...}
method insert(|) {...}
method next(|) {...}
method count(|) {...}
method update(|) {...}
method delete(|) {...}
method sql(| --> Str) {...}
