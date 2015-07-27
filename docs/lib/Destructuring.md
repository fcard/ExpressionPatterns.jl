Destructuring.Structure
==========

#### DestructureTree

`DestructureTree`s are created from [`PatternTree`](./PatternStructure.md#patterntree)s in [`destructure`](./Destructuring.md#destructure)
to aid destructuration.

Subtypes:
- [`DestructureNode`](./Destructuring.md#destructurenode)
- [`DestructureBind`](./Destructuring.md#destructurebind)
- [`DestructureLeaf`](./Destructuring.md#destructureleaf)
- [`DestructureSlurp`](./Destructuring.md#destructureslurp)

Relevant functions
- `insert!`
- [`depth`](./Destructuring.md#depth)

---
#### DestructureNode

Created from a [[`PatternNode`](./PatternStructure.md#patternnode)](./PatternStructure.md#patternnode). Can have any number of children
(each corresponding to a child of the [[`PatternNode`](./PatternStructure.md#patternnode)](./PatternStructure.md#patternnode)). It doesn't
have a head value, since it's irrelevant to destructuring. It retains
the step, however. Has a slurp [`depth`](./Destructuring.md#depth), and a `name` that is used
to name a temporary variable containing the arguments of the expression
being destructured.

example:
```julia
# N is a DestructureNode that destructures (x+y),
# with name `:n` and step ArgsStep

binding_code(N, :(x+y)) ==
quote
  let n = ArgsStep(:(1+2))
    x = n[1]
    y = n[2]
  end
end

```

Related:
- [`DestructureTree`](./Destructuring.md#destructuretree)

---
#### DestructureBind

Created from a [`PatternGate`](./PatternStructure.md#patterngate) whose test is a [`Binding`](./PatternStructure.md#binding).
Represents a variable binding, keeping track of its name.

example:
```julia
# B is a DestructureBind whose name is `:a`

binding_code(B, 1) == :(a = 1)

```

Related:
- [`DestructureTree`](./Destructuring.md#destructuretree)

---
#### DestructureLeaf

Created from a [`PatternLeaf`](./PatternStructure.md#patternleaf), `DestructureLeaf`s signify
that there is nothing to be done.

e.g. A destructuring tree of :(1+x) is a [`DestructureNode`](./Destructuring.md#destructurenode) whose
children are a `DestructureLeaf` (1) and a [`DestructureBind`](./Destructuring.md#destructurebind) (x).
The code constructuded from that code would more or less be
```julia
let temp = :(1+x).args
  nothing # code from the leaf
  x = temp[2]
end
```

Related:
- [`DestructureTree`](./Destructuring.md#destructuretree)

---
#### DestructureSlurp

Created from a [`PatternNode`](./PatternStructure.md#patternnode) with a [`SlurpHead`](./PatternStructure.md#slurphead) head. It has
a destructuring `func`tion that extracts elements from a list
of expressions.

Has a `match` function that checks if it can still extract
arguments from a list of expressions, and a `postmatch`
function that checks if the remaining children of its
parent node can match a list of expressions. They are used
by the destructuring function to know when to keep going,
stop or reverse the element extraction.

`DestructureSlurp`s also keep track of its bindings names
via a expr (see `slurp_get_bindings`).

```julia
# S is a DestructureSlurp constructed from :(*{f(a,b)},c-d,e)
# Below is a approximation on how a greedy slurp uses S.match
# (matches to f(a,b)) and S.postmatch (matches to (c-d, e)).

ex = :((1+2),(3/4),(5-6),x)
args = ex.args

a = Any[]
b = Any[]
f = Any[]

function pushvalues(ex)
  push!(f, ex.args[1])
  push!(a, ex.args[2])
  push!(b, ex.args[3])
end

function popvalues()
  pop!(f)
  pop!(a)
  pop!(b)
end

S.match(args[1]) # true, so push values
pushvalues(args[1])

S.match(args[2]) # true
pushvalues(args[2])

S.match(args[3]) # true
pushvalues(args[3])

S.match(args[4]) # true
pushvalues(args[4])

S.match(args[5]) # false, stop

S.postmatch(args[5:end]) # false, pop
popvalues()

S.postmatch(args[4:end]) # false
popvalues()

S.postmatch(args[3:end]) # true, stop
popvalues(a,b)

f == [*,/]
a == [1,3]
b == [2,4]

```

---
#### DestructuringInformation

Packs a [`DestructureTree`](./Destructuring.md#destructuretree), the declarations of the bindings,
and one [`Variables`](./Matching.md#variables) object.

---
#### depth

`depth(DestructureTree) -> Int`

Gets the slurp `depth` of a [`DestructureTree`](./Destructuring.md#destructuretree), e.g. from the trees
constructed of `:a`, `:[*{a}]`, and `:[*{[*{a}]}],)`, `a` has
`depth` of respectively 0, 1, and 2.

---


Destructuring.Slurps
==========

#### slurp_functions

`slurp_functions(SlurpHead) -> Function`

Obtains the binding function that corresponds to the given [`SlurpHead`](./PatternStructure.md#slurphead).

---
#### set_slurp_bindings!

`set_slurp_bindings!(DestructureSlurp)`

Obtains the binding variables of the slurp with [`get_slurp_bindings`](./Destructuring.md#get_slurp_bindings) and
sets them to the `bindings` parameter of the [`DestructureSlurp`](./Destructuring.md#destructureslurp).

---
#### get_slurp_bindings

`get_slurp_bindings(DestructureSlurp) -> Expr`

Obtains the binding variables of a slurp in the form of a `Expr`.
The representation is best shown in examples:

| slurp        | result      |
|--------------|-------------|
| `*{x}`       |`:[x]`       |
| `*{x,y}`     |`:[x,y]`     |
| `*{(x,y),z}` |`:[[x,y],z]` |

The expr is later evaluated and passed to the slurp's binding function.

---
#### extract!

`extract!(slurp, bindings, values) -> remaining values`

Extracts arguments from values and put them in the
binding variables, returning the remaining values.

---
#### retract!

`retract!(bindings, tree)`

Pops out values attributed to binding variables, reverting
the actions of a [`extract!`](./Destructuring.md#extract!) call.

---
#### add_binding_iteration!

`add_binding_iteration!(slurp, bindings, tree)`

For nested slurps. Adds a new array to binding
variables, where elements will be extracted to.

example:
We want to destructure the expression `:[[1,2,3,4]]`
with the slurp `:[*{[*{a,b}]}]`. The initial values of
`a` and `b` is `Any[]`, but since `a` and `b` are within
a nested slurp, the values need to be extracted to a
array within an array. We call `add_binding_iteration!`,
and now `a` and `b` have the value `Any[Any[]]`.

(after the slurp, `a=Any[Any[1,3]]`, `b=Any[Any[2,4]]`)

---


Destructuring.CodeGeneration
==========

#### code

`code(info, ex, body) -> Expr`

Using the bindings in `info` and `ex` being the value to
to be deconstructed, creates the code that is returned
by [`destructure`](./Destructuring.md#destructure).

---
#### declare_bindings

`declare_bindings(bindingcode, declarations, value, ex, body) -> Expr`

Adds the declarations of the variables to the binding code.

---


Destructuring.Function
==========

#### destructure

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

---


Destructuring.Applications
==========

#### letds

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

---
#### macrods

```julia
@macrods name(p1,p2,...,pn) begin
  ...
end
```

Defines a macro with destructuring properties.

examples:
```julia
@macrods swap((x,y)) :($y,$x)
@macrods split(:C{at} => [*{a}, at, *{b}]) (a,b)

@swap((1,2)) == (2,1)
@split(3 => [1,2,3,4,5]) == (Any[1,2], Any[4,5])

```

---
#### macrods

```julia
@macrods name(p1,p2,...,pn) begin
  ...
end
```

Defines a macro with destructuring properties.

examples:
```julia
@macrods swap((x,y)) :($y,$x)
@macrods split(:C{at} => [*{a}, at, *{b}]) (a,b)

@swap((1,2)) == (2,1)
@split(3 => [1,2,3,4,5]) == (Any[1,2], Any[4,5])

```

---
#### anonds

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

---
#### anonds

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

---


