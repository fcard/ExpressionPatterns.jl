Pattern Language Overview
==========

Special syntax
--------------
| Syntax                     | Description                                               |
|----------------------------|-----------------------------------------------------------|
| `:B{x}` <br> `:binding{x}`    | Represents a name binding; matches anything. Symbols that start with a letter, `#` or `@` are automatically considered to be bindings.|
| `:E{v}` <br> `:EQ{v}` <br> `:equals{v}` | Matches if the expression is equal to `v`.|
| `:T{t}` <br> `:type{t}` <br> `:T{p,t}` <br> `:type{p,t}` | Tests if a expression is of the given type `t`. If a pattern `p` is supplied along with the type, this tries to match the expression with `p` after the type check.
| `:P{f}` <br> `:predicate{f}` <br> `:P{p,f}` <br> `:predicate{p,f}` | Matches by calling the given predicate `f` on the expression. If a pattern `p` is supplied, this tries to match the expression with `p` after the predicate check.|
| `:L{p}` <br> `:literal{p}`     | Turns autobinding off in `p`, meaning no symbol is automatically considered a binding. |
| `:A{p}` <br> `:autobinding{p}` | Turns autobinding on in `P`. |
| `:I{xs}` <br> `:iterable{xs}`  | Matches a non-expr iterable object. |
| `:R{:h, args}` <br> `:raw{:h, args}` | Matches `Expr(:h, args)`. |

**examples**:
```julia

:(x+y)                 # matches :(1+2), :(a+b), :((a,b)+(b,c))

:(:L{x+y})             # only matches :(x+y)

:(:L{:A{x}+y})         # matches :(1+y), :(a+y)...
                       # Same as :(:L{:B{x}+y}), :(x+:L{y}) or :(x+EQ{:y})

:(:T{:P{iseven}, Int}) # matches all integer literals that are even

x = :symbol; :(EQ{x})  # matches :symbol. Note that equals\E\EQ calls eval on its argument.
                       # Same with predicate\P and type\T.

:(:I{a,b,*{xs}})       # matches [1,2,3,4], (:a,:b,:c,:d,:e)

:(:R{:import, *{ms}})  # matches :(import M.m), :(import ..M.N.m)

```

Slurps
-------

A slurp works like `*` quantifiers in regular expressions, matching 0 or more of the pattern with the arguments of an expression. They are created with `*{p}` (greedy, matches as much as possible) or `:?{p}` (lazy, match as little as possible). Slurps can have multiple arguments, e.g. `*{a,b,c}`, and in this case each argument is matched in a looping sequence, e.g. when matching `[*{a,b,c}]` with       `:[1,2,3,4,5,6]`, `a` is matched with `1`, b with `2`, `c` with `3`, then `a` with `4`, `b` with `5` and `c` with `6`. Note that if the expression had been `:[1,2,3,4,5]` the match would fail, since every subpattern must match for a loop to count.  

Slurps can be nested: `[*{[*{1,2}]}]` matches expressions like `:[[1,2,1,2], [1,2], [1,2,1,2,1,2]]`. In destructuring, `[*{[*{x,y}]}]` will have `x` and `y` be vectors of vectors, e.g. `[*{[*{x,y}]}] = :[[1,2,1,2], [1,2], [1,2,1,2,1,2]] -> x=[[1,1], [1], [1,1,1,1], y=[[2,2], [2], [2,2,2,2]]`. If `x` was within three slurps, it would have been a vector of vectors of vectors, etc.

**examples**:
```julia

:(*{1},)             # matches :(1,1,1,1), :(1,1,1,1,1,1), :()

:[*{odd,even}]       # matches :[1,2,3,4,5,6], odd=[1,3,5], even=[2,4,6]

:[*{x},:?{y}]        # matches :[1,2,3,4], x=[1,2,3,4], y=[]

:[:?{x},*{y}]        # matches :[1,2,3,4], x=[], y=[1,2,3,4]

:(f(*{:T{Symbol}}))  # matches :(f(x,y)), :("g"(a,b,c)), but not :(f(1,2)) or :(g(a,b,3))

:[*{funs(*{args})}]  # matches :[1+2, map(f, coll), sin(x)],
                     # f=[:+,:f,:sin], args=[[1,2],[:f,:coll],[:x]]


```

