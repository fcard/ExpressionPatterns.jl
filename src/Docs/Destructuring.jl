#----------------------------------------------------------------------------
# Destructuring.Function;
#----------------------------------------------------------------------------
import ..Destructuring.Function: destructure, code


"""
`destructure(pattern, value, body)`

Creates a let expression where every binding name in `pattern` is attributed
a correspond value found in `value`, with `body` begin the body of the let expression.

examples:
```julia

eval(destructure(:(x+y), :(:(1+2)), quote x,y end))  #> (1,2)

eval(destructure(:(*{x}), :(:(1,2,3)), quote x end)) #> [1,2,3]

pattern = :(for x in coll; b end)
value   = :(for i in 1:10; print(i) end)
eval(destructure(pattern, :value, quote x,coll,b end)) #> (:x, :(1:10), :(print(x))
```

"""
destructure;

"""
`code(vars, ptree, body) -> Expr`


"""
code;


#----------------------------------------------------------------------------
# Destructuring.Applications;
#----------------------------------------------------------------------------
import ..Destructuring.Applications: @letds, @macrods, @anonds, @funds, Applications

"""
```julia
@letds p1=v1 p2=v2 ... pn=vn begin
  ...
end
```

Let expression with destructuring properties.

examples:
```julia
@letds f(x::T1,y::T2) = :(add(a::Int,b::Int)) begin
    f == :add && x == :a && y == :b && T1 == T2 == :Int
end

@letds [*{[*{x,y}]}] = :[[1,2,3,4],[a,b,c,d]] begin
  x == Any[Any[1,3], Any[:a, :c]] &&
  y == Any[Any[2,4], Any[:b, :d]]
end

@letds [*{x}, 3, *{y}] = :[1,2,3,4,5] begin
  x == Any[1,2] && y == Any[3,4]
end
```

"""
:(Applications.@letds);

"""
```julia
@macrods name(p1,p2,...,pn) begin
  ...
end
```

Defines a macro with destructuring properties.

examples:
```julia
@macrods swap((x,y)) :(\$y,\$x)
@macrods split(:C{at} => [*{a}, at, *{b}]) (a,b)

@swap((1,2)) == (2,1)
@split(3 => [1,2,3,4,5]) == (Any[1,2], Any[4,5])

```

"""
:(Applications.@macrods);

"""
```julia
@anonds (p1,p2,...,pn) -> body
```

Defines an anonymous function with destructuring properties.

examples:
```julia
extremes = @anonds [first, *{middle}, last] -> (first, last)
extremes(:[1,2,3,4]) == (1,4)

first_index = @anonds (:C{i} => [?{x}, i, *{a}]) -> length(x)+1
last_index  = @anonds (:C{i} => [*{x}, i, *{a}]) -> length(x)+1

ex = :(0 => [1,1,1,0,1,1,0])
first_index(ex) == 4
last_index(ex)  == 7

```

"""
:(Applications.@anonds);

"""
```julia
@funds name(p1,p2,...,pn) = body
```

Defines an function with destructuring properties.

examples:
```julia
@funds odd_even([*{odd,even}]) = (odd, even)
odd_even(:[1,2,3,4,5,6]) == (Any[1,3,5],Any[2,4,6])

@funds extract_int([*{a}, :T{x, Integer}, *{b})) = x
extract_int(:[a,b,4,d,e,f,g]) == 4

```

"""
:(Applications.@funds);
