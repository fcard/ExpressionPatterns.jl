module SlurpOptimizations
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
using  ...PatternStructure.Special
export optimize_slurps!

#-----------------------------------------------------------------------------------
# dispatch function
#-----------------------------------------------------------------------------------

function optimize_slurps!(node)
  slurps = reverse(find(is_slurp, node.children))
  optimize_slurps!(node, slurps, [])
end

function optimize_slurps!(node, slurps, after)
  isempty(slurps) && return

  i = slurps[1]
  slurp = node.children[i]

  if isempty(after) # last slurp
    if is_simple_slurp(slurp)
       node.children[i] = make_simple_last_slurp(slurp, node, i)

    elseif is_simple_alternating_slurp(slurp)
      # simple alternating last slurp | (..., *{a,b,c..})
    end
  else
    gates  = find(x->isa(x, PatternGate), node.children[i+1:after[1]-1])
    equals = filter(j->isa(node.children[i+j].check, EqualityCheck), gates)

    if !isempty(equals)
      eqvalues = map(j->(node.children[i+j].check.value, i+j), equals)

      if is_simple_slurp(slurp)
        until, index = eqvalues[1]
        node.children[i] = make_simple_slurp_until_one(slurp, node, until, index-i)
        
      elseif is_simple_alternating_slurp(slurp)
	# alternating slurp until X | (..., *{a,b,c...}, X, ...)
      end
    end
  end
  push!(after, i)
  optimize_slurps!(node, slurps[2:end], after)
end

#-----------------------------------------------------------------------------------
# maker functions
#-----------------------------------------------------------------------------------

make_slurp(slurp, head) =
  PatternNode(head, SlurpStep(), slurp.children, slurp.consts)

make_simple_last_slurp(slurp, node, i) =
  make_slurp(slurp, SimpleLastSlurp(length(node.children) - i))

make_simple_slurp_until_one(slurp, node, until, index) =
  make_slurp(slurp,
              isa(slurp.head, GreedySlurp)?
                SimpleGreedySlurpUntil([until], index) :
                SimpleLazySlurpUntil([until], index))

#-----------------------------------------------------------------------------------
# conditions
#-----------------------------------------------------------------------------------

function is_simple_slurp(slurp)
  length(slurp.children) == 1 &&
  is_binding(slurp.children[1])
end

function is_simple_alternating_slurp(slurp)
  length(slurp.children) > 1 &&
  all(is_binding, slurp.children)
end

function is_binding(node::PatternGate)
  isa(node.check, Binding) &&
  isa(node.child, PatternLeaf)
end
is_binding(x) = false

end
