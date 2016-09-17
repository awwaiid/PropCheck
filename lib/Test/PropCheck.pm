unit module Test::QuickCheck;

use Test;

multi gen(Int) { 1000000.rand.Int }

multi gen(Array[Int]) {
  (^10).map({ gen(Int) }).Array
}

multi gen(Positional[Int]) {
  my Int @thing = (^10).map({ gen(Int) }).list;
  @thing;
}

our sub verify-one( &f, &predicate, :$input-pattern ) {
  CATCH {
    default {
      if $_ ~~ /"Constraint type check failed for parameter"/ {
        return True;
      }
      .rethrow;
    }
  }
  my $sig = $input-pattern || &f.signature;
  my @params = $sig.params.map: -> $p {
    gen($p.type)
  }
  my $result = &f(|@params);
  my $is-ok = so &predicate($result);
  ($is-ok, @params, $result);
}

our sub verify(&f, &predicate, :$input-pattern) {
  for ^1000 {
    my ($is-ok, @result) = verify-one(&f, &predicate, :$input-pattern);
    if !$is-ok {
      return (False, @result);
    }
  }
  True;
}

our sub qc-verify(&f, &predicate, $note = "", :$input-pattern) is export {
  my ($ok, $in-out) = verify(&f, &predicate, :$input-pattern);
  ok $ok, $note;
  if !$ok {
    diag "Failing call: {&f.name}{$in-out[0].flat.list.perl}";
    diag "      output: {$in-out[1].perl}";
  }
}

multi sub quick-check(&property, Signature $input-pattern, $note = '') is export {
  qc-verify(
    &property,
    -> $n { $n },
    $note,
    input-pattern => $input-pattern);
}

multi sub quick-check(&property, Str $note = '') is export {
  qc-verify(
    &property,
    -> $n { $n },
    $note);
}

