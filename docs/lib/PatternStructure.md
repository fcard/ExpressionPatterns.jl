PatternStructure.Trees
==========

#### PatternTree

PatternTree is an expression pattern represented as a tree
data structure. It can be a root, check, node or leaf.

Subtypes:
- [`PatternLeaf`](./PatternStructure.md#patternleaf)
- [`PatternNode`](./PatternStructure.md#patternnode)
- [`PatternRoot`](./PatternStructure.md#patternroot)
- [`PatternGate`](./PatternStructure.md#patterngate)


Relevant functions:
- `insert!`
- [`newleaf!`](./PatternStructure.md#newleaf!)
- [`newnode!`](./PatternStructure.md#newnode!)

---
#### PatternRoot

`PatternRoot` is the root of a pattern tree. It can
have one child. It's used to simplify initialization
of pattern trees.

Related:
- [`PatternTree`](./PatternStructure.md#patterntree)

---
#### PatternNode

`PatternNode` is a node from a pattern tree. It can
have any number of children. It has a head value
much like Exprs. It also has a `step` functor that
is used to extract argument from the expression
it's trying to match. Nodes also keep track of
which of its children, if any, are slurps.

Related:
- [`PatternStep`](./PatternStructure.md#patternstep)
- [`PatternHead`](./PatternStructure.md#patternhead)
- [`PatternTree`](./PatternStructure.md#patterntree)

---
#### PatternGate

`PatternGate` has one child and a test. A expression
is only matched against the child if it passes the
test.

example:
```julia
  tree = analyze(:(x+y)).child
  vars = Variables(constants(tree))
  test = PredicateCheck(ex->all(iseven, ex.args[2:end]))
  gate = PatternGate(test)
  insert!(gate, tree)

  matchtree(gate, :(2+4), vars) == true  # passes test and matches the pattern
  matchtree(gate, :(2-4), vars) == false # passes test but doesn't match the pattern
  matchtree(gate, :(1+4), vars) == false # fails test, no attempt to match

# this particular pattern can be created more easily with:
  test  = ex->all(iseven, ex.args[2:end])
  match = matcher(:(:P{(x+y), $test}))
  match(:(2+4)) == true
  match(:(2-4)) == false
  match(:(1+4)) == false
```

Related:
- [`PatternTree`](./PatternStructure.md#patterntree)
- [`PatternCheck`](./PatternStructure.md#patterncheck)

---
#### PatternLeaf

PatternLeaves signify the end of the pattern. Matching anything to
a leaf always return true.

Related:
- [`PatternTree`](./PatternStructure.md#patterntree)

---
#### PatternCheck

PatternChecks are tests to be applied to expressions.
If an pattern is passed as an argument to a check,
the expression will be matched against the pattern
if it passes the test.

Types of test:

- [`TypeCheck`](./PatternStructure.md#typecheck)
- [`EqualityCheck`](./PatternStructure.md#equalitycheck)
- [`PredicateCheck`](./PatternStructure.md#predicatecheck)

---
#### PatternStep

PatternStep is one component of pattern nodes. It is used to extract
the arguments of the expression in a way that they can be matched by
the children of the node.

Types of step:

- [`ArgsStep`](./PatternStructure.md#argsstep)
- [`QuoteStep`](./PatternStructure.md#quotestep)
- [`BlockStep`](./PatternStructure.md#blockstep)
- [`SlurpStep`](./PatternStructure.md#slurpstep)

---
#### PatternHead

Represents the type of a [`PatternNode`](./PatternStructure.md#patternnode).

Subtypes:
- `ExprHead`
- [`SlurpHead`](./PatternStructure.md#slurphead)

---
#### makenode

`makenode(head, step) -> PatternNode`

Creates a [`PatternNode`](./PatternStructure.md#patternnode) with the provided `head` and `step`.

Related:
- [`PatternNode`](./PatternStructure.md#patternnode)
- [`PatternStep`](./PatternStructure.md#patternstep)

---
#### newnode!

`newnode!(head, step, parent) -> PatternNode`

Creates a [`PatternNode`](./PatternStructure.md#patternnode) from the provided `head` and `step`
and inserts the node into `parent`.
(returns the new node)

Related:
- [`PatternNode`](./PatternStructure.md#patternnode)
- [`PatternStep`](./PatternStructure.md#patternstep)
- [`PatternGate`](./PatternStructure.md#patterngate)

---
#### newleaf!

`newleaf!(check, parent) -> PatternLeaf`

Creates a [`PatternLeaf`](./PatternStructure.md#patternleaf), inserts it into a [`PatternGate`](./PatternStructure.md#patterngate)
along with the check, and then inserts the gate into `parent`.

Related:
- [`PatternLeaf`](./PatternStructure.md#patternleaf)
- [`PatternStep`](./PatternStructure.md#patternstep)
- [`PatternGate`](./PatternStructure.md#patterngate)

---


PatternStructure.Checks
==========

#### Binding

`Binding` represents an assignment to a name.
Any symbol that starts with a letter, `'@'`, `'#'` (gensyms)
are automatically considered to be bindings.
Use `:binding{x}`\`:B{x}` to transform `x` into a binding
name, with `x` being any symbol.

`:literal{P}`\`:L{P}` makes so that no symbol in `P` is considered
a binding name. `:autobinding{P}`\`:A{P}` removes the `:literal`
effect.

---
#### EqualityCheck

`EqualityCheck` is a [`PatternCheck`](./PatternStructure.md#patterncheck) that tests
if an expression is equal to some value.

---
#### TypeCheck

`TypeCheck` is a [`PatternCheck`](./PatternStructure.md#patterncheck) that tests
if an expression is of some type.

---
#### PredicateCheck

`PredicateCheck` is a [`PatternCheck`](./PatternStructure.md#patterncheck) that tests
if an expression fulfills some predicate.

---
#### ArgsStep

`ArgsStep` is a [`PatternStep`](./PatternStructure.md#patternstep) that extracts
the arguments from a expression unmodified.

---
#### BlockStep

`BlockStep` is a [`PatternStep`](./PatternStructure.md#patternstep) that extracts
the non-line-number arguments from a expression.

---
#### QuoteStep

`QuoteStep` is a [`PatternStep`](./PatternStructure.md#patternstep) that extracts
the value of a `QuoteNode` or the arguments
from a `:quote` expression.

---
#### SlurpStep

Since slurps already work with extracted
arguments, there is no need for a step for
them, this being a placeholder.
Calling `SlurpStep` causes an error.

---


PatternStructure.SlurpTypes
==========

#### SlurpHead

Represents a slurp algorithm. Can be a [`LazySlurp`](./PatternStructure.md#lazyslurp) or a [`GreedySlurp`](./PatternStructure.md#greedyslurp), and
many variations of each.

Subtypes:
- [`LazySlurp`](./PatternStructure.md#lazyslurp)
- [`GreedySlurp`](./PatternStructure.md#greedyslurp)
- [`GenericLazySlurp`](./PatternStructure.md#genericlazyslurp)
- [`GenericGreedySlurp`](./PatternStructure.md#genericgreedyslurp)
- [`SimpleLastSlurp`](./PatternStructure.md#simplelastslurp)

---
#### LazySlurp

Match as many arguments as possible, then try
to match the rest of pattern, putting back
arguments from the slurp if neccessary.

---
#### GreedySlurp

Only try to match the slurp if the pattern after it
can't match the expression.

---
#### GenericLazySlurp

Slowest version of a [`LazySlurp`](./PatternStructure.md#lazyslurp), but works for any pattern.

---
#### GenericGreedySlurp

Slowest version of a [`GreedySlurp`](./PatternStructure.md#greedyslurp), but works for any pattern.

---
#### SimpleLastSlurp

Assumes the slurp is the last one, and its match a single symbol.
If the expression is of the form `*{s}, a₁,...,aₙ`, capture
everything minus the last `n` arguments.

---


PatternStructure.Special
==========

#### is_binding_name

`is_binding_name(sym) -> Bool`

Determines if `sym` is to be automatically considered
a binding name. Returns `true` if `sym` starts with a
letter, `_`, `#` or `@`.

---


