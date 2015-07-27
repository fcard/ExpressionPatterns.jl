module Structure
using  ...PatternStructure.SlurpTypes
import ...Matching.Consistency: Variables
import ...PatternStructure.Trees: PatternStep
import ...PatternStructure.Special: is_slurp
export DestructureTree, DestructureRoot, DestructureSlurp,
       DestructureNode, DestructureLeaf, DestructureBind,
       DestructuringInformation, depth

#----------------------------------------------------------------------------
# DestructureTree
#----------------------------------------------------------------------------

abstract DestructureTree

immutable DestructureLeaf <: DestructureTree
end

immutable DestructureBind <: DestructureTree
  name  :: Symbol
  depth :: Int
end

type DestructureRoot <: DestructureTree
  child :: DestructureTree
  DestructureRoot() = new()
end

immutable DestructureSlurp <: DestructureTree
  head      :: SlurpHead
  depth     :: Int
  func      :: Function
  match     :: Function
  postmatch :: Function
  unmatch   :: Function
  bindings  :: Expr
  children  :: Vector{DestructureTree}
  DestructureSlurp(head, depth, func, match, postmatch, consts) =
    new(head, depth, func, match, postmatch, consts, :(Any[]), DestructureTree[])
end

immutable DestructureNode <: DestructureTree
  step     :: PatternStep
  depth    :: Int
  name     :: Symbol
  children :: Vector{DestructureTree}
  DestructureNode(step, depth) =
    new(step, depth, gensym("node"), DestructureTree[])
end

import Base: insert!
insert!(root ::DestructureRoot,  x) = root.child = x
insert!(node ::DestructureNode,  x) = push!(node.children,  x)
insert!(slurp::DestructureSlurp, x) = push!(slurp.children, x)

depth(d::DestructureRoot) = 0
depth(d::DestructureTree) = d.depth

#----------------------------------------------------------------------------
# DestructuringInformation
#----------------------------------------------------------------------------

immutable DestructuringInformation
  tree         :: DestructureTree
  vars         :: Variables
  declarations :: Vector{DestructureBind}

  DestructuringInformation(tree, vars) =
    new(tree, vars, DestructureBind[])
end



end
