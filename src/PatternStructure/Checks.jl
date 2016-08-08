module Checks
using  ...PatternStructure.Trees
import ...Helper: linesof
export EqualityCheck, TypeCheck, PredicateCheck,
       ArgsStep, QuoteStep, BlockStep,
       IterStep, SlurpStep


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

(::ArgsStep)(ex)  = ex.args
(::BlockStep)(ex) = linesof(ex)

(::QuoteStep)(ex::Expr) = ex.args
(::QuoteStep)(ex::QuoteNode) = [ex.value]

(::IterStep)(ex)  = ex
(::SlurpStep)(ex) = error("Called the step of slurp.")

end
