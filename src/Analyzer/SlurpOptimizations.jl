module SlurpOptimizations
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
using  ...PatternStructure.Special
export optimize_slurps!

#-----------------------------------------------------------------------------------
# dispatch function
#-----------------------------------------------------------------------------------

function optimize_slurps!(node, i)
  i == 0 && return

  child = node.children[i]
  if is_slurp(child)
  	if is_last_slurp(node, i)

  	   if is_simple_slurp(child)
     	  node.children[i] = make_simple_last_slurp(child, node, i)
       else
       	  #simple alternating last slurp | (..., *{a,b,c..})
       end

  	else
  	  # slurp until X | (...,*{a}, X, ...)
  	  # alternating slurp until X | (..., *{a,b,c...}, X, ...)
  	end
  end
  optimize_slurps!(node, i-1)
end

#-----------------------------------------------------------------------------------
# maker functions
#-----------------------------------------------------------------------------------

function make_simple_last_slurp(child, node, i)
  PatternNode(SimpleLastSlurp(length(node.children) - i),
              SlurpStep(),
              child.children,
              child.consts)
end

#-----------------------------------------------------------------------------------
# conditions
#-----------------------------------------------------------------------------------

function is_last_slurp(node, i)
  !any(is_slurp, node.children[i+1:end])
end

function is_simple_slurp(child)
  length(child.children) == 1 &&
  is_binding(child.children[1])
end

function is_simple_alternating_slurp(child)
  length(child.children) > 1 &&
  all(is_binding, child.children)
end

function is_binding(node::PatternGate)
  isa(node.check, Binding) &&
  isa(node.child, PatternLeaf)
end
is_binding(x) = false

end