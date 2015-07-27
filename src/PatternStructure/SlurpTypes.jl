module SlurpTypes
import ...PatternStructure.Trees: PatternHead
export SlurpHead, LazySlurp, GreedySlurp, GenericGreedySlurp, GenericLazySlurp,
       SimpleLastSlurp

abstract SlurpHead   <: PatternHead
abstract LazySlurp   <: SlurpHead
abstract GreedySlurp <: SlurpHead

immutable GenericLazySlurp   <: LazySlurp end
immutable GenericGreedySlurp <: GreedySlurp end

immutable SimpleLastSlurp <: GreedySlurp
  post::Int
end

end