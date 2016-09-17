
use lib 'lib';
use Test;
use Test::PropCheck;

sub is-even($n) { $n %% 2 }

sub timestwo(Int $n) { $n * 2 }

sub timesthree(Int $n) { $n * 3 }

sub mult(Int $n, Int $m) { $n * $m }

qc-verify(&timestwo, &is-even, 'Multiply by two is always even');
qc-verify(&timesthree, &is-even, 'Multiply by three is always even');
qc-verify(&timesthree, * %% 2, 'Multiply by three is always even');
qc-verify(&mult, * %% 2, 'Integer multiply is always even');

sub wrap(Int $n where * %% 2, Int $m where * %% 2) { mult($n, $m) }
qc-verify(&wrap, * %% 2, 'Even integer multiply is always even');

qc-verify(
  -> Int $n where * %% 2, Int $m where * %% 2 { mult($n, $m) },
  * %% 2,
  'Even integer multiply is always even');

qc-verify(
  &mult,
  * %% 2,
  'Even integer multiply is always even',
  input-pattern => :(Int $n where * %% 2, Int $m where * %% 2));

sub prop-idempotent(@stuff) {
  sort @stuff == sort sort @stuff
}

quick-check &prop-idempotent, :( Array of Int );

quick-check { (sort @^m).min == (sort @^m)[0] }, :( Array of Int );

sub prop-min-first(Array[Int] $stuff) { (sort $stuff).min == (sort $stuff)[0] }

quick-check &prop-min-first;

done-testing;

