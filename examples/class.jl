module Classes
using  ExpressionPatterns.Dispatch
export @class

include("classprep.jl")

@macromethod class(:T{name, Symbol}, block) esc(:(@class ($name) <: ($Object) ($block)))

@macromethod class(:T{name, Symbol} <: superclass, begin *{exprs} end) begin
  parameters, constructor = classinfo(name, exprs)

  esc(
  quote
    type $name <: $superclass
      $(parameters...)

      $name(::$ClassId) = new()
    end
    $constructor
    $name
  end)
end


function classinfo(name, exprs)
  info = ClassInfo()
  for expr in exprs
    interpret_expr!(name, info, expr)
  end
  parameters  = info.parameters
  constructor = make_constructor(name, info, info.constructor)

  parameters, constructor
end


@metafunction interpret_expr!(:C{name}, info, (name(*{args}) = expr)) =
  interpret_expr!(info, :(function constructor($(args...)) $expr end))


@metafunction interpret_expr!(:C{name}, info, function name(*{args}) *{statements} end) begin
  if info.constructor.arguments == :undef
    info.constructor.arguments  = args
    info.constructor.statements = statements
  else
   error("This class implementations only accepts one inner constructor!")
  end
end

@metafunction interpret_expr!(name, info, function f(*{xs}) *{statements} end) =
  interpret_expr!(info, :($f($(xs...)) = begin $(statements...) end))

@metafunction interpret_expr!(name, info, f(*{xs}) = expr) begin
  if !(:(($f)::($Function)) in info.parameters)
    push!(info.parameters, :(($f)::($Method)))
    push!(info.constructor.method_defs, :($f($(xs...)) = $expr; this.$f = $Method{$name}($f)))
    push!(info.constructor.new_args, f)
  end
end

@metafunction interpret_expr!(name, info, (:T{x,Symbol}=a)) =
  interpret_expr!(info, :($x::Any=$a))

@metafunction interpret_expr!(name, info, (:T{x,Symbol}::T=a)) begin
  push!(info.parameters, :($x::$T))
  push!(info.constructor.param_defs, :($x = $a; this.$x = $x))
  push!(info.constructor.new_args, x)
end

@metafunction interpret_expr!(name, info, (:T{x,Symbol})) =
  interpret_expr!(info, :($x::Any))

@metafunction interpret_expr!(name, info, (:T{x,Symbol}::T)) begin
  push!(info.parameters, :($x::$T))
  push!(info.undefined,  :($x::$T))
  push!(info.constructor.new_args, x)
end

@metafunction make_def(x::T) = :(this.$x = $x)

# usage

@class Point begin
  x::Number
  y::Number

  add(p) = Point(this.x + p.x, this.y + p.y)
  distanceto(p) = sqrt((this.x-p.x)^2 + (this.y-p.y)^2)
end

Point(1,2).add(Point(1,2)).distanceto(Point(2,4))


@class VectorObject begin
  elements::Vector=[]

  push(a) = (push!(this.elements, a); this)
end

V = VectorObject()
V.push(1).push(2).push(3)


abstract Shape <: Object

@class Square <: Shape begin
  a::Point
  b::Point
  c::Point
  d::Point

  function Square(a,b,c,d)
    @assert a.distanceto(b) ==
            b.distanceto(c) ==
            c.distanceto(d)

    this.a = a
    this.b = b
    this.c = c
    this.d = d
  end
end
points(xs) = map(x->Point(x...), xs)
Square(points([(0,0),(2,0),(2,2),(0,2)])...)
end
