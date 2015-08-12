module SlurpTypes
import ...PatternStructure.Trees: SlurpHead
export SlurpHead, LazySlurp, GreedySlurp, GenericGreedySlurp, GenericLazySlurp,
       SimpleLastSlurp, SimpleGreedySlurpUntil, SimpleLazySlurpUntil, SimpleSlurp

abstract LazySlurp   <: SlurpHead
abstract GreedySlurp <: SlurpHead

immutable GenericLazySlurp   <: LazySlurp end
immutable GenericGreedySlurp <: GreedySlurp end

#-----------------------------------------------------------------------------------
# Simple: slurp is composed of one single binding name, e.g. *{a}
#-----------------------------------------------------------------------------------

abstract SimpleGreedySlurp <: GreedySlurp
abstract SimpleLazySlurp   <: LazySlurp

immutable SimpleLastSlurp <: SimpleGreedySlurp
  post::Int
end

immutable SimpleGreedySlurpUntil <: SimpleGreedySlurp
  until::Vector
  index::Int
end

immutable SimpleLazySlurpUntil <: SimpleLazySlurp
  until::Vector
  index::Int
end

typealias SimpleSlurp Union{SimpleGreedySlurp, SimpleLazySlurp}
end