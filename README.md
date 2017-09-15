<sub>**Release**/**Master**</sub></br>
![Build (Release & Master)](https://travis-ci.org/fcard/ExpressionPatterns.jl.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/fcard/ExpressionPatterns.jl/badge.svg)](https://coveralls.io/github/fcard/ExpressionPatterns.jl)

Installing
--------
julia 0.6:
```julia
Pkg.add("ExpressionPatterns")
```

---

Otherwise:
```julia
Pkg.clone("https://github.com/fcard/ExpressionPatterns.jl")

# julia 0.5
Pkg.checkout("ExpressionPatterns", "julia-v0.5")

# julia 0.4
Pkg.checkout("ExpressionPatterns", "julia-v0.4")
```

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

@metafunction getpath(M.m) = [getpath(M); m] # this defines the getpath(args...) method
getpath(M::Symbol) = [M]

getpath(:(M1.M2.m)) == [:M1, :M2, :m]


@macromethod inverse_op(x+y) :($x-$y)
@macromethod inverse_op(x-y) :($x+$y)
@macromethod inverse_op(x*y) :($x/$y)
@macromethod inverse_op(x/y) :($x*$y)

@inverse_op(10+20) == -10
@inverse_op(10-20) ==  30
@inverse_op(10*20) ==  .5
@inverse_op(10/20) == 200


# macros created with @macromethod can be extended in other modules

module M1
using ExpressionPatterns.Dispatch
@macromethod f(x+y) 1
end

module M2
using ExpressionPatterns.Dispatch
@metamodule import ..M1.@f
@macromethod f(x-y) 2
end

M1.@f(1+2) == 1
M1.@f(1-2) == 2


```

Dispatch Reflection
------------------
```julia
using ExpressionPatterns.Dispatch
using ExpressionPatterns.Dispatch.Reflection

@macromethod f(x+y, z)[method1] = [x,y]
@macromethod f(z, x+y)[method2] = [x,y]

@whichmeta @f(x+y,y+x) #> f(x+y, z)


@prefer @f(z, x+y) over @f(x+y, z)

@whichmeta @f(x+y,y+x) #> f(z, x+y)


@prefer method1 over method2 in @f

@whichmeta @f(x+y,y+x) #> f(x+y, z)


@metaconflicts @f #> <<z> <x+y>> | <<x+y> <z>>

@remove @f(z,x+y)

@metaconflicts @f #> nothing

```

See [Language.md](./docs/Language.md) for information on the pattern language.

See [the examples](./examples/) or [the tests](./test/) for more uses.

Y'all should also check [MacroTools](https://github.com/MikeInnes/MacroTools.jl), which inspired me to remake and publish this in the first place!
