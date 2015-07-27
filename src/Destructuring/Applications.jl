module Applications
using  ...Destructuring.Function
using  ...Helper
import Base.Meta: isexpr, quot
export @letds, @macrods, @anonds, @funds

DA = Applications

#----------------------------------------------------------------------------
# Utilities
#----------------------------------------------------------------------------

function destructure_all(patterns, values, body)
  destructure(:($(patterns...),), :(Expr(:tuple, $(values...))), body)
end

#----------------------------------------------------------------------------
# Destructuring let
#----------------------------------------------------------------------------

macro letds(lets...)
  esc(letds(lets[1:end-1], lets[end]))
end

function letds(lets, body)
  patterns, values = unzip(map(x->x.args, lets))
  destructure_all(patterns, values, body)
end

#----------------------------------------------------------------------------
# Destructuring macro
#----------------------------------------------------------------------------

macro macrods(signature, body)
  name      = signature.args[1]
  patterns  = Expr(:tuple, signature.args[2:end]...)

  esc(:(macro $name(args...)
          $DA.@letds $patterns = Expr(:tuple, args...) $body end))
end

#----------------------------------------------------------------------------
# Destructuring anonymous function
#----------------------------------------------------------------------------

@macrods anonds(patterns -> body) begin
  esc(anonds(patterns, body))
end

anonds(p::Symbol, body) = anonds_impl(:($p,), body)
anonds(p::Expr,  body)  = anonds_impl(p.head == :tuple? p : :($p,), body)

function anonds_impl(patterns, body)
  :((args...) ->
      $DA.@letds $patterns = Expr(:tuple, args...) $body)
end

#----------------------------------------------------------------------------
# Destructuring named function
#----------------------------------------------------------------------------

@macrods funds(name(*{patterns}) = body) begin
  esc(funds(name, patterns, body))
end

function funds(name, patterns, body)
  :(function $name(args...)
      $DA.@letds $(Expr(:tuple, patterns...)) = Expr(:tuple, args...) $body end)
end

#----------------------------------------------------------------------------

end