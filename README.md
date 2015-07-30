Matching
--------
```julia
using ExpressionPatterns.Matching

m1 = matcher(:(x+y))

m1(:(1+2)) == true
m1(:(1-2)) == false

m2 = matcher(:(f(*{args})))

m2(:(g(1,2))) == true
m2(:(h()))    == true
m2(:(x+y))    == true
m2(:(A{T}))   == false

```


Destructuring
-------------
```julia
using ExpressionPatterns.Destructuring

@letds (x+y)=:(1+2) begin
  x,y == (1,2)
end


@macrods first_arg(f(first,*{rest})) first

@first_arg(f(1,2)) == 1


gettype = @anonds (a::T) -> T
gettype(:(x::Integer)) == :Integer

@funds getvalue(a::T) = a
getvalue(:(x::Integer)) == :x


```

Dispatch
--------
```julia
using ExpressionPatterns.Dispatch

@metafunction getname(M.m) = getname(m)
getname(m::Symbol) = m

getname(:(M1.M2.m)) == :m


@macromethod inverse_op(x+y) :($x-$y)
@macromethod inverse_op(x-y) :($x+$y)
@macromethod inverse_op(x*y) :($x/$y)
@macromethod inverse_op(x/y) :($x*$y)

@inverse_op(10+20) == -10
@inverse_op(10-20) ==  30
@inverse_op(10*20) ==  .5
@inverse_op(10/20) == 200


# macros created with @macromethod can be extended in other modules

module M
using ExpressionPatterns.Dispatch
  @macromethod f(x+y) 1
end

@metamodule import .M.@f
@macromethod f(x-y) 2

@f(1+2) == 1
@f(1-2) == 2


```

Dispatch Utilities
------------------
```julia
using ExpressionPatterns.Dispatch
using ExpressionPatterns.Dispatch.MetaUtilities

@macromethod f(x+y, z)[lab1]  = [x,y]
@macromethod f(z, x+y)[lab2]  = [x,y]

@whichmeta @f(x+y,y+x) #> f(x+y, z)


@prefer @f(z, x+y) over @f(x+y, z)

@whichmeta @f(x+y,y+x) #> f(z, x+y)


@prefer lab1 over lab2 in @f

@whichmeta @f(x+y,y+x) #> f(x+y, z)


@metaconflicts @f #> <<z> <x+y>> | <<x+y> <y>>

@remove @f(z,x+y)

@metaconflicts @f #> nothing

```

See [Language.md](./docs/Language.md) for information on the pattern language.
