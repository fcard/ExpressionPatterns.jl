module Environment
using  ...PatternStructure.Trees
using  ...PatternStructure.Special
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
using  ...Analyzer.SlurpOptimizations
using  ...Helper
export Variables, SlurpRanges, match_variable!, unmatch_variable!, extract!, add_slurp_range!

typealias Variables   Dict{Symbol, Any}
typealias SlurpRanges Dict{PatternNode, Vector{Range}}

function match_variable!(v::Variables, name::Symbol, value)
  haskey(v, name)?
    (v[name] == value) :
    (v[name] =  value; true)
end

function extract!(v::Variables, tree::PatternNode, args, ai, mi, ranges)
  for b in bindings(tree)
    v[b] = Any[]
  end
  extract_slurp!(tree.head, v, tree, args, ai:mi, ranges)

end

function extract_values!(v::Variables, tree::PatternNode, value, ranges)
  args  = tree.step(value)
  index = 1

  for child in tree.children
    if is_slurp(child)
      range = shift!(ranges[child])
      index = last(range)+1

      for b in bindings(child)
        add_binding_iteration!(child.depth, b,v)
      end

      extract_slurp!(child.head, v, child, args, range, ranges)

    else
      extract_values!(v, child, args[index], ranges)
      index += 1

    end
  end
end

function extract_values!(v::Variables, tree::PatternGate, value, ranges)
  if isa(tree.check, Binding)
     binding = get_binding(v, tree.check.name, tree.depth)
     push!(binding, value)
  end

  extract_values!(v, tree.child, value, ranges)
end

function extract_values!(v::Variables, tree::PatternLeaf, value, ranges)
end

function extract_slurp!(h, v, tree, args, range, ranges)
  child = Looping(tree.children)
  for i in range
    extract_values!(v, current(child), args[i], ranges)
    next!(child)
  end
end

function extract_slurp!(h::SimpleSlurp, v, tree, args, range, ranges)
  binding = get_binding(v, tree.children[1].check.name, tree.depth)
  append!(binding, args[range])
end

function get_binding(v, name, depth)
  binding = v[name]

  while depth > 1
    depth  -= 1
    binding = binding[end]
  end

  return binding
end

function add_binding_iteration!(depth, b, v)
  binding = v[b]
  while depth > 2
    depth  -= 1
    binding = binding[end]
  end
  push!(binding, Any[])
end

function add_slurp_range!(ranges, slurp, range)
  if !haskey(ranges, slurp)
    ranges[slurp] = []
  end
  push!(ranges[slurp], range)
end


function unmatch_variable!(v::Variables, names)
  for name in names
  	if v.count[name] >  1
  	   v.count[name] -= 1
  	else
  	   delete!(v.count,  name)
  	   delete!(v.values, name)
  	end
  end
end

end
