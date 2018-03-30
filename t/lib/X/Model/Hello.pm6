use DBO::Model;
unit class X::Model::Hello does DBO::Model['hello', 'X::Row::Hello'];

has @.columns = [
  id => {
    type           => 'integer',
    nullable       => False,
    auto_increment => 1,
  },
  txt => {
    type           => 'text',
  },
];
