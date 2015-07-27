module Checks
using  ...PatternStructure.Trees
import ...Helper: linesof
export EqualityCheck, TypeCheck, PredicateCheck, Binding,
       ArgsStep, QuoteStep, BlockStep,
       IterStep, SlurpStep


immutable Binding <: PatternCheck
  name::Symbol
end

immutable EqualityCheck{T} <: PatternCheck
  value::T
end

immutable TypeCheck{T} <: PatternCheck
end

immutable PredicateCheck <: PatternCheck
  predicate :: Function
end


immutable ArgsStep  <: PatternStep end
immutable BlockStep <: PatternStep end
immutable QuoteStep <: PatternStep end
immutable IterStep  <: PatternStep end
immutable SlurpStep <: PatternStep end

import Base: call

call(::ArgsStep, ex)  = ex.args
call(::BlockStep, ex) = linesof(ex)

call(::QuoteStep, ex::Expr) = ex.args
call(::QuoteStep, ex::QuoteNode) = [ex.value]

call(::IterStep, ex)  = ex
call(::SlurpStep, ex) = error("Called the step of slurp.")

end
