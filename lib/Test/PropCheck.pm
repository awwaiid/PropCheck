unit module Test::QuickCheck;

use Test;

multi gen(Int) { 1000000.rand.Int }
# multi gen(Int $n where * %% 2) { (1000000.rand / 2).Int  }

multi gen(Array[Int]) {
  note "gen: Array[Int]";
  (^10).map({ gen(Int) }).Array
}

# multi gen(Positional) {
#   note "Positional!";
#   # (^(100.rand.Int)).map({ gen(Int) }).Array
#   (^(100.rand.Int)).map({ gen(Int) }).list
# }

our sub verify-one( &f, &predicate, :$input-pattern ) {
  CATCH {
    default {
      # say "caught: {$_.gist}";
      if $_ ~~ /"Constraint type check failed for parameter"/ {
        return True;
      }
      .rethrow;
    }
  }
  my $sig = $input-pattern || &f.signature;
  my @params = &f.signature.params.map: -> $p {
    # say "Param: {$p.gist}";
    # say "Param: {$p.type}";
    gen($p.type)
  }
  # say "Params: {@params.gist}";
  my $result = &f(|@params);
  # say "Result: {$result.gist}";
  my $is-ok = so &predicate($result);
  ($is-ok, @params, $result);
}

our sub verify(&f, &predicate, :$input-pattern) {
  for ^1000 {
    # return False unless verify-one(&f, &predicate);
    my ($is-ok, @result) = verify-one(&f, &predicate, :$input-pattern);
    if !$is-ok {
      return (False, @result);
    }
  }
  True;
}

our sub qc-verify(&f, &predicate, $note = "", :$input-pattern) is export {
  my ($ok, $in-out) = verify(&f, &predicate, :$input-pattern);
  # $test-num++;
  ok $ok, $note;
  if !$ok {
    diag "Failing call: {&f.name}{$in-out[0].flat.list.perl}";
    diag "      output: {$in-out[1].perl}";
  }
  # if $ok {
  #   # say "ok $test-num - $note";
  #   ok $note;
  # } else {
  #   say "not ok $test-num - $note # {$in-out[0].gist} -> {$in-out[1].gist}";
  # }
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

