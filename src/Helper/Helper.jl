module Helper
export @implicit,
       unzip, remove,
       linesof, exprmodify, clean_code,
       Looping, next!, current, restart!

#-----------------------------------------------------------------------------------
# Looping
#-----------------------------------------------------------------------------------

type Looping
  iter
  state

  Looping(iter) = new(iter, start(iter))
end

current(l::Looping) =
  next(l.iter, l.state)[1]

restart!(l::Looping) =
  l.state = start(l.iter)

function next!(l::Looping)
  l.state = next(l.iter, l.state)[2]

  done(l.iter, l.state) && restart!(l)
end

#-----------------------------------------------------------------------------------
# @implicit
#-----------------------------------------------------------------------------------

macro implicit(vars, block)
  esc(implicit(vars, block))
end

function implicit(varsym::Symbol, block)
  implicit(Expr(:tuple, varsym), block)
end

function implicit(vars_expr::Expr, block)
  vars = vars_expr.args
  functions = map(function_name, filter(is_function_definition, block.args))

  add_implicit(vars, functions, block)
end

function add_implicit(vars, functions, block)
  exprmodify(block, on=callto(functions)) do ex
    Expr(:call, ex.args..., vars...)
  end
end

callto(functions) =
  ex -> is_call(ex) && ex.args[1] in functions

#-----------------------------------------------------------------------------------
# Functional utilities
#----------------------------------------------------------------------------------

never(::Any)  = false
always(::Any) = true

#-----------------------------------------------------------------------------------
# Iterable utilities
#-----------------------------------------------------------------------------------

function unzip(A)
  F = []; S = []
  for (first, second) in A
    push!(F, first)
    push!(S, second)
  end
  return F,S
end

function remove(f, A)
  B = []
  for x in A
    !f(x) && push!(B, x)
  end
  return B
end

#-----------------------------------------------------------------------------------
# Metaprogramming utilities
#-----------------------------------------------------------------------------------

is_line_number(ex::Expr) = ex.head == :line
is_line_number(ex::LineNumberNode) = true
is_line_number(ex) = false

is_function_definition(ex) = false
is_function_definition(ex::Expr) =
  ex.head == :function ||
  ex.head == :(=) && is_call(ex.args[1])

is_call(ex) = false
is_call(ex::Expr) = ex.head == :call

function_name(ex) = ex.args[1].args[1]

function linesof(ex::Expr)
  remove(is_line_number, ex.args)
end

exprmodify(modify; on=always) =
  ex -> exprmodify(modify, ex, on=on)

exprmodify(modify, ex; on=always) =
  on(ex)? modify(ex) : ex

exprmodify(modify, ex::Expr; on=always) =
  on(ex)? modify(ex) : Expr(ex.head, map(exprmodify(modify, on=on), ex.args)...)

function clean_code(ex::Expr)
  nex = Expr(ex.head, map(clean_code, ex.args)...)

  nex.head == :block && return Expr(:block, linesof(nex)...)
  nex.head == :(->)  && return Expr(:(->),  nex.args[1], nex.args[2].args[1])
  nex
end
clean_code(x) = x

end