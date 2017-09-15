module Helper
export @implicit,
       unzip, remove,
       linesof, exprmodify, clean_code,
       Looping, next!, current, restart!

#-----------------------------------------------------------------------------------
# Looping
#-----------------------------------------------------------------------------------

mutable struct Looping
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

function linesof(ex::Expr)
  remove(is_line_number, ex.args)
end

function clean_code(ex::Expr)
  nex = Expr(ex.head, map(clean_code, ex.args)...)

  nex.head == :block && return Expr(:block, linesof(nex)...)
  nex.head == :(->)  && return Expr(:(->),  nex.args[1], nex.args[2].args[1])
  nex
end
clean_code(x) = x

end
