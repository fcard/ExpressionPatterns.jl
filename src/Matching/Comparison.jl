module Comparison
using  ...Matching.Environment
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
import Base: ==, ⊆
export compare_trees, conflicts, ⊇;

==(a::PatternTree, b::PatternTree) = compare_trees(a,b) == :equal
 ⊇(a::PatternTree, b::PatternTree) = compare_trees(a,b) in [:equal, :superset]
 ⊆(a::PatternTree, b::PatternTree) = compare_trees(a,b) in [:equal, :subset]

conflicts(a::PatternTree, b::PatternTree) = compare_trees(a,b) == :conflicts

newvars() = Variables()

function compare_trees(a::PatternTree, b::PatternTree)
  compare_trees(a, b, newvars(), newvars())
end

function compare_trees(a::PatternRoot, b::PatternRoot, vars1, vars2)
  compare_trees(a.child, b.child, vars1, vars2)
end

function compare_trees(a::PatternNode, b::PatternNode, vars1, vars2)
  (a.head != b.head || length(a.children) != length(b.children)) && return :unequal


  results = compare_children(a,b,vars1, vars2)
  all(x->x==:equal,   results) && return :equal
  all(x->x==:unequal, results) && return :unequal

  if (:conflicts in results) ||
     (:superset  in results  && :subset in results)

    return :conflicts
  end

  :superset in results && return :superset
  :subset   in results && return :subset

  return :unequal
end

function compare_children(a, b, vars1, vars2)
  map(c->compare_trees(c..., vars1, vars2), zip(a.children, b.children))
end

function compare_trees(a::PatternGate, b::PatternGate, vars1, vars2)
  checks =  compare_checks(a.check, b.check, vars1, vars2)
  checks == :equal?
     compare_trees(a.child, b.child, vars1, vars2) : checks
end

function compare_trees(a::PatternGate, b, vars1, vars2)
  checks =  compare_checks(a.check, b, vars1, vars2)
  checks == :superset? :superset : :unequal
end

function compare_trees(a, b::PatternGate, vars1, vars2)
  checks =  compare_checks(a, b.check, vars1, vars2)
  checks == :subset? :subset : :unequal
end

function compare_checks(a::Binding, b::Binding, vars1, vars2)
  match_variable!(vars1, a.name, b.name) &&
  match_variable!(vars2, b.name, a.name)  ? :equal : :unequal
end

function compare_checks(a::Binding, b, vars1, vars2)
  match_variable!(vars1, a.name, b)? :superset : :unequal
end

function compare_checks(a, b::Binding, vars1, vars2)
  match_variable!(vars2, b.name, a)? :subset : :unequal
end

function compare_checks(a::EqualityCheck, b::EqualityCheck, vars1, vars2)
  a.value == b.value? :equal : :unequal
end

function compare_checks(a::PredicateCheck, b::PredicateCheck, vars1, vars2)
  a.predicate == b.predicate? :equal : :unequal
end

function compare_checks{T1,T2}(a::TypeCheck{T1}, b::TypeCheck{T2}, vars1, vars2)
  T1 == T2? :equal    :
  T2 <: T1? :superset :
  T1 <: T2? :subset   :
            :unequal
end
compare_checks(a, b, vars1, vars2) = :unequal

compare_trees(a::PatternLeaf, b::PatternLeaf, vars1, vars2) = :equal
compare_trees(a, b, vars1, vars2) = :unequal

end