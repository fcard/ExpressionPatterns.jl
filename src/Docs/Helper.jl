#-----------------------------------------------------------------------------------
# Helper;
#-----------------------------------------------------------------------------------
import ..Helper: Looping, current, next!, restart!, @implicit,
         unzip, remove, is_line_number, linesof, exprmodify, Helper


"""
`Looping(iterable)` creates an objects that permits
iterating an infinite repetition of `iterable`.

`current(L::Looping)` gets the current element.

`next!(L)` makes `current(L)` return the next object.
if the current object is the last of the iterable,
start from the beginning.

`restart!(L)` makes `current(L)` return the first
object.

"""
Looping;

"""
`current(L::Looping)` returns the current element,
which can be changed through `next!` and `restart!`.

"""
current;


"""
Makes `current(L::Looping)` return the next object.
if the current object is the last of the iterable,
start from the beginning.

"""
next!;

"""
Makes `current(L::Looping)` return the first object.

"""
restart!;


"""
```julia
@implicit v₁,v₂,...,vₙ begin
  ...
end
```

Introduces variables by having them be added as the
last parameters of every function defined in the
begin-end block, as well as having them be passed
to every call of these functions. For example:

```julia
@implicit y begin
  f(x) = g(x,y)
  h(x) = f(x)
end
```

is the same as:

```julia
f(x,y) = g(x,y)
h(x,y) = f(x,y)
```

Note that functions defined outside the block
do not have implicit arguments passed to them.

This is used to avoid having to write the same
argument over and over again. It's specially
annoying when the argument is just being passed
around and is only used in a few places.

```julia
f(x, data) = g(do_stuff1(x), data)
g(x, data) = h(do_stuff2(x), data)
h(x, data) = do_stuff3(x,data)
```
```julia
@implicit data begin
  f(x) = g(do_stuff1(x))
  g(x) = h(do_stuff2(x))
  h(x) = do_stuff3(x,data)
end
```

"""
:(Helper.@implicit);


"""
`unzip(Iterable{Tuple{F,S}}) -> Tuple{Vector{F}, Vector{S}}`

Takes a iterable of the form `[(x₁,y₁), (x₂,y₂), ..., (xₙ, yₙ)]` and
transforms it  
in `([x₁, x₂, ..., xₙ], [y₁, y₂, ..., yₙ])`

"""
unzip;

"""
`remove((T -> Bool), Iterable{T}) -> Vector{T}`

Takes a function `f` and a collection and return that
collection with all elements `x` for which `f(x)` is
true removed.

"""
remove;

"""
`is_line_number(ex) -> Bool`

Returns true if `ex` represents a line number.
(`LineNumberNode` or `Expr(:line)`)

"""
is_line_number;

"""
`linesof(Expr) -> Expr`

Takes a block expression and return all non-linenumber
elements from it.

"""
linesof;

"""
`exprmodify(modify, expr; on) -> Expr`

Takes a modifier function, an expression and a predicate (`on`),
and walks down the expression, calling `modify` on any argument
`x` for which `on(x)` returns true.

example:

```julia
ex = :("a10",("Bc", "cd"))
alphastr(x) = isa(x, AbstractString) && isalpha(x)
exprmodify(uppercase, ex, on=alphastr) == :("a10", ("BC", "CD"))
```

"""
exprmodify;