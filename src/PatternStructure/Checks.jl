module Checks
using  ...PatternStructure.Trees
import ...Helper: linesof
export EqualityCheck, TypeCheck, PredicateCheck,
       ArgsStep, QuoteStep, BlockStep,
       IterStep, SlurpStep


struct EqualityCheck{T} <: PatternCheck
  value::T
end

struct TypeCheck{T} <: PatternCheck
end

struct PredicateCheck <: PatternCheck
  predicate :: Function
end


struct ArgsStep  <: PatternStep end
struct BlockStep <: PatternStep end
struct QuoteStep <: PatternStep end
struct IterStep  <: PatternStep end
struct SlurpStep <: PatternStep end

(::ArgsStep)(ex)  = ex.args
(::BlockStep)(ex) = linesof(ex)

(::QuoteStep)(ex::Expr) = ex.args
(::QuoteStep)(ex::QuoteNode) = [ex.value]

(::IterStep)(ex)  = ex
(::SlurpStep)(ex) = error("Called the step of slurp.")

end
