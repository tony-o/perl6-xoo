unit module X::DB::Exception;

class TypeConflict is Exception is export {
  has $.type;
  has $.value;

  method message($e) {
    "{$.value.gist} is not compatible with {$.type}";
  }
};

class JSONParse is Exception is export {
  method message($x) { 'Invalid json.' }
};

class ValueTooLarge is Exception is export {
  has $.type;
  has $.value;
  has $.size;

  method message($e) {
    "{$.value.gist} is too large for column of type {$.type}({$.size})";
  }
}

class Generic is Exception is export {
  has $.message;

  method message($e) {
    $!message;
  }
}
