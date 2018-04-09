use DBO::Row;
unit class X::Row::Order does DBO::Row;

#convenience methods
method reopen-duplicate {
  my $new-order = self.duplicate;
  $new-order.status('open');
  $new-order.update;
  $new-order;
}
