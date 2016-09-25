module Printing
using  ...PatternStructure.Special
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
import ...Helper: clean_code
import Base: show

function show(io::IO, p::PatternTree)
  print(io, "pattern`$(clean_code(expr(p)))`")
end

function expr(p::PatternRoot)
  expr(p.child)
end

function expr(p::PatternNode)
  children::Vector{Any} = map(expr, p.children)

  if is_macrocall(p.head)
     children[1] = Symbol("@$(children[1])")
  end

  is_special(p)?
     Expr(:curly, QuoteNode(patterntype(p)), children...) :
     Expr(p.head.sym, children...)

end

function expr(p::PatternGate)
  isa(p.check, Binding)?        p.check.name  :
  isa(p.check, EqualityCheck)?  p.check.value :
  isa(p.check, TypeCheck)?      :(:type{$(expr(p.child)), $(typeof(p.check).parameters[1])}) :
  isa(p.check, PredicateCheck)? :(:predicate{$(expr(p.child)), $(p.check.predicate)}) :
  throw(ArgumentError("invalid check type in PatternGate: $(p.check)"))
end

is_macrocall(head::ExprHead) = head.sym == :macrocall
is_macrocall(head) = false

"""
 expr(PatternTree) -> Expr|Symbol|Node

 Converts a pattern tree to an expression.

"""
expr;

end
