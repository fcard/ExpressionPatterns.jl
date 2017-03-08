module SlurpTypes
import ...PatternStructure.Trees: SlurpHead
export SlurpHead, LazySlurp, GreedySlurp, GenericGreedySlurp, GenericLazySlurp,
       SimpleLastSlurp, SimpleGreedySlurpUntil, SimpleLazySlurpUntil, SimpleSlurp

abstract type LazySlurp   <: SlurpHead end
abstract type GreedySlurp <: SlurpHead end

struct GenericLazySlurp   <: LazySlurp end
struct GenericGreedySlurp <: GreedySlurp end

#-----------------------------------------------------------------------------------
# Simple: slurp is composed of one single binding name, e.g. *{a}
#-----------------------------------------------------------------------------------

abstract type SimpleGreedySlurp <: GreedySlurp end
abstract type SimpleLazySlurp   <: LazySlurp end

struct SimpleLastSlurp <: SimpleGreedySlurp
  post::Int
end

struct SimpleGreedySlurpUntil <: SimpleGreedySlurp
  until::Vector
  index::Int
end

struct SimpleLazySlurpUntil <: SimpleLazySlurp
  until::Vector
  index::Int
end

const SimpleSlurp = Union{SimpleGreedySlurp, SimpleLazySlurp}
end
