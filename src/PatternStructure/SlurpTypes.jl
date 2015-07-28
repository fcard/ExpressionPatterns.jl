module SlurpTypes
import ...PatternStructure.Trees: PatternHead
export SlurpHead, LazySlurp, GreedySlurp, GenericGreedySlurp, GenericLazySlurp,
       SimpleLastSlurp, SimpleGreedySlurpUntil, SimpleLazySlurpUntil

abstract SlurpHead   <: PatternHead
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

end