unit role DB::Xoos::Role::Searchable;

has $!filter;

multi submethod BUILD(:$!filter = { }) { }
method !filter {$!filter;}

method search(|) {...}
method first(|) {...}
method last(|) {...}
method all(|) {...}
method next(|) {...}
method count(|) {...}
method update(|) {...}
method delete(|) {...}
method sql(| --> Str) {...}
