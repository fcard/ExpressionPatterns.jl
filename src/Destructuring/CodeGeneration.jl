module CodeGeneration
using  ...Destructuring.Structure
export code

#----------------------------------------------------------------------------
# code: creates the code that declares and bind all variables
#----------------------------------------------------------------------------

function code(info, ex, body)
  @gensym value
  bcode = binding_code(info.tree.child, value)
  bcode = declare_bindings(bcode, info.declarations, value, ex, body)
  bcode
end

#----------------------------------------------------------------------------
# declare_bindings!: creates the code that declares the variables
#----------------------------------------------------------------------------

function declare_bindings(bcode, decls, value, ex, body)
  decls_code = declarations(decls)
  value_bind = Expr(:(=), value, ex)
  final_code = Expr(:let, quote $bcode; $body end, value_bind, decls_code...)
end

function declarations(decls)
  result = []
  for d in decls
    slurpdef = :($(d.name) = Any[])

    if (d.name   in result && d.depth >  0) ||
       (slurpdef in result && d.depth == 0)
      error(conflicting_slurp_def(d.name))
    else
      push!(result, d.depth == 0? d.name : slurpdef)
    end
  end
  result
end

conflicting_slurp_def(v) = """
  Variable $v has a conflicting definition. It cannot be inside and
         outside a slurp at the same time.
  """

#----------------------------------------------------------------------------
# binding_code: creates the code that bind the variables to their values
#----------------------------------------------------------------------------

binding_code(::DestructureLeaf, value) =
  nothing

binding_code(b::DestructureBind, value) =
  :($(b.name) = $value)

binding_code(tree::DestructureNode, value) =
  :(let $(tree.name) = $(tree.step)($value)
        $(bind_children(tree.children, tree.name)...) end)

function bind_children(children, name)
  indx = 1
  map(children) do child
    bcode = binding_code(child, :($name[$indx]))
    indx += isa(child, DestructureSlurp)? 0 : 1
    bcode
  end
end

function binding_code(tree::DestructureSlurp, value)
  name = value.args[1]
  indx = value.args[2]
  func = :($(tree.func)($(tree), $(tree.bindings), $name[$indx:end]))

  :($name = [$name[1:$indx-1]; $func])
end


end