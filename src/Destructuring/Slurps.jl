module Slurps
using  ...Destructuring.Structure
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
export slurp_functions, set_slurp_bindings!

#----------------------------------------------------------------------------
# get function
#----------------------------------------------------------------------------

slurp_functions(::GenericLazySlurp)       = lazy_slurp_bind!
slurp_functions(::GenericGreedySlurp)     = greedy_slurp_bind!
slurp_functions(::SimpleLastSlurp)        = simple_last_slurp_bind!
slurp_functions(::SimpleGreedySlurpUntil) = simple_greedy_slurp_until_bind!
slurp_functions(::SimpleLazySlurpUntil)   = simple_lazy_slurp_until_bind!

#----------------------------------------------------------------------------
# set_slurp_bindings!
#----------------------------------------------------------------------------

function set_slurp_bindings!(slurp)
  slurp.bindings.args = get_slurp_bindings(slurp).args
end

function get_slurp_bindings(tree::DestructureTree)
  expr = :(Any[])
  for child in tree.children
      push!(expr.args, get_slurp_bindings(child))
  end
  expr
end

get_slurp_bindings(binding::DestructureBind) = binding.name

get_slurp_bindings(leaf::DestructureLeaf) = :()

#----------------------------------------------------------------------------
# Extract/Retract: how slurps manipulate their bindings
#----------------------------------------------------------------------------

function extract_args!(slurp, bindings, values, node)
  for i in eachindex(bindings)
    if isa(node.children[i], DestructureSlurp)
       add_binding_iteration!(slurp, bindings[i], node.children[i])
       values = node.children[i].func(node.children[i], bindings[i], values)
    else
       extract!(slurp, bindings[i], values[1], node.children[i])
       values = values[2:end]
    end
  end
  values
end

function extract!(slurp, bindings, value, node::DestructureNode)
  values = node.step(value)
  extract_args!(slurp, bindings, values, node)
end

function extract!(slurp, binding, value, tree::DestructureBind)
  depth = tree.depth
  while depth > 1
    depth -= 1
    binding = binding[end]
  end
  push!(binding, value)
end

function extract!(slurp, binding, values, tree::DestructureLeaf)
  nothing
end


function add_binding_iteration!(slurp, bindings, tree::DestructureTree)
  for (b,d) in zip(bindings, tree.children)
    add_binding_iteration!(slurp, b, d)
  end
end

function add_binding_iteration!(slurp, bindings, tree::DestructureBind)
  depth = slurp.depth
  while depth > 1
    depth -= 1
    bindings = bindings[end]
  end
  push!(bindings, Any[])
end

function get_single_binding(slurp, bindings)
  depth   = slurp.depth
  binding = bindings
  while depth != 0
    binding = binding[end]
    depth  -= 1
  end
  binding
end

function retract!(bindings, tree::DestructureTree)
  for (b,d) in zip(bindings, tree.children)
    retract!(b,d)
  end
end
retract!(bindings, tree::DestructureBind)  = pop!(bindings)
retract!(bindings, tree::DestructureSlurp) = map(pop!, bindings)
retract!(bindings, tree::DestructureLeaf)  = nothing

#----------------------------------------------------------------------------
# Implementations of the various slurp types
#----------------------------------------------------------------------------

function lazy_slurp_bind!(slurp, bindings, values)
  while !slurp.postmatch(values)
    values = extract_args!(slurp, bindings, values, slurp)
  end
  return values
end

#----------------------------------------------------------------------------

function greedy_slurp_bind!(slurp, bindings, values)
  bindlen   = length(bindings)
  oldvalues = values

  while length(values) >= bindlen && slurp.match(values[1:bindlen])
    values = extract_args!(slurp, bindings, values, slurp)
  end
  vlen = length(oldvalues) - length(values) + 1

  while !slurp.postmatch(oldvalues[vlen:end])
    vlen -= bindlen
    map(retract!, bindings, slurp.children)
    slurp.unmatch()
  end

  return oldvalues[vlen:end]
end

#----------------------------------------------------------------------------

function simple_last_slurp_bind!(slurp, bindings, values)
  binding = get_single_binding(slurp, bindings)

  append!(binding, values[1:end-slurp.head.post])
  values[end-slurp.head.post+1:end]
end

#----------------------------------------------------------------------------

function simple_lazy_slurp_until_bind!(slurp, bindings, values)
  slurp.postmatch(values) && return values

  until = slurp.head.until
  index = slurp.head.index
  found = filter(x->x>=index, findin(values, until))

  start   = 1
  after   = 1
  binding = get_single_binding(slurp, bindings)

  while !slurp.postmatch(values[after:end])
    after = found[1]-index+1
    found = found[2:end]
    append!(binding, values[start:after-1])
    start = after
  end
  values[after:end]
end


#----------------------------------------------------------------------------

function simple_greedy_slurp_until_bind!(slurp, bindings, values)
  until = slurp.head.until
  index = slurp.head.index
  found = reverse(filter(x->x>=index, findin(values, until)))

  binding = get_single_binding(slurp, bindings)
  result  = values[1:found[1]-index]

  while !slurp.postmatch(values[found[1]-index+1:end])
    result = values[1:found[2]-index]
    found  = found[2:end]
  end
  append!(binding, result)

  return values[found[1]-index+1:end]
end


#----------------------------------------------------------------------------
end
