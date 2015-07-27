#-----------------------------------------------------------------------------------
# PatternStructure.Trees;
#-----------------------------------------------------------------------------------
import ..PatternStructure.Trees: PatternTree, PatternRoot, PatternNode,  PatternLeaf,
                                 PatternGate, PatternStep, PatternCheck, PatternHead,
                                 ExprHead, makenode, newnode!, newleaf!, slicenode
"""
PatternTree is an expression pattern represented as a tree
data structure. It can be a root, check, node or leaf.

Subtypes:
- `PatternLeaf`
- `PatternNode`
- `PatternRoot`
- `PatternGate`


Relevant functions:
- `insert!`
- `newleaf!`
- `newnode!`

"""
PatternTree;

"""
`PatternRoot` is the root of a pattern tree. It can
have one child. It's used to simplify initialization
of pattern trees.

Related:
- `PatternTree`

"""
PatternRoot;

"""
`PatternNode` is a node from a pattern tree. It can
have any number of children. It has a head value
much like Exprs. It also has a `step` functor that
is used to extract argument from the expression
it's trying to match. Nodes also keep track of
which of its children, if any, are slurps.

Related:
- `PatternStep`
- `PatternHead`
- `PatternTree`

"""
PatternNode;

"""
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
  match = matcher(:(:P{(x+y), \$test}))
  match(:(2+4)) == true
  match(:(2-4)) == false
  match(:(1+4)) == false
```

Related:
- `PatternTree`
- `PatternCheck`

"""
PatternGate;

"""
PatternLeaves signify the end of the pattern. Matching anything to
a leaf always return true.

Related:
- `PatternTree`

"""
PatternLeaf;

"""
PatternChecks are tests to be applied to expressions.
If an pattern is passed as an argument to a check,
the expression will be matched against the pattern
if it passes the test.

Types of test:

  **TypeCheck**  
  `description   `: Tests if an expression is of a given type.  
  `name\shortcut `: `(:type)`\\`(:T)`  
  `pattern usage `: `(:T{Type})` or `(:T{pattern, Type})`  

-
  **EqualityCheck**  
  `description   `: Tests if an expression is equal to some value.  
  `name\shortcut `: `(:equals)`\\`(:EQ)`\\`(:E)`  
  `pattern usage `: `(:EQ{val})` or `(:EQ{pattern, val})` or use a literal (`10`,`'a'`,etc.)  

-
  **PredicateCheck**  
  `description   `: Tests if an expression fulfills some predicate.  
  `name\shortcut `: `(:predicate)`\\`(:P)`  
  `pattern usage `: `(:P{func})` or `(:P{pattern, func})`  

"""
PatternCheck;

"""
PatternStep is one component of pattern nodes. It is used to extract
the arguments of the expression in a way that they can be matched by
the children of the node.

Types of step:

`ArgsStep`: takes the args of the expression without modification.

`QuoteStep`: if the expression is a QuoteNode, take its value,
if the expression is a :quote Expr, take its argument.

`BlockStep`: Filter out the LineNumberNodes and :line Exprs.

`SlurpStep`: Only exists because slurps are just pattern nodes
with special names. This step is not used.

"""
PatternStep;

"""
Represents the type of a `PatternNode`.

Subtypes:
- `ExprHead`
- `SlurpHead`

"""
PatternHead;

"""
`makenode(head, step) -> PatternNode`

Creates a `PatternNode` with the provided `head` and `step`.

Related:
- `PatternNode`
- `PatternStep`

"""
makenode;

"""
`newnode!(head, step, parent) -> PatternNode`

Creates a `PatternNode` from the provided `head` and `step`
and inserts the node into `parent`.
(returns the new node)

`newnode!(check, head, step, parent) -> PatternNode`

Creates a `PatternNode` with `head` and `step`, inserts
it into a `PatternGate` along with the check, and inserts
the gate into `parent`.

Related:
- `PatternNode`
- `PatternStep`
- `PatternGate`

"""
newnode!;

"""
`newleaf!(parent) -> PatternLeaf`

Creates a `PatternLeaf` and inserts it into `parent`.
(returns the new leaf)

`newleaf!(check, parent) -> PatternLeaf`

Creates a `PatternLeaf`, inserts it into a `PatternGate`
along with the check, and then inserts the gate into `parent`.

Related:
- `PatternLeaf`
- `PatternStep`
- `PatternGate`

"""
newleaf!;

"""
`slicenode(node, first:last)`

Creates a pattern node that matches the children of `node` at
the given interval.

Related:
- `PatternNode`

"""
slicenode;


#-----------------------------------------------------------------------------------
# PatternStructure.Checks;
#-----------------------------------------------------------------------------------
import ..PatternStructure.Checks: Binding, EqualityCheck, TypeCheck, PredicateCheck,
                                  ArgsStep, BlockStep, QuoteStep, SlurpStep


"""
`Binding` represents an assignment to a name.
Any symbol that starts with a letter, `'@'`, `'#'` (gensyms)
are automatically considered to be bindings.
Use `:binding{x}`\\`:B{x}` to transform `x` into a binding
name, with `x` being any symbol.

`:literal{P}`\\`:L{P}` makes so that no symbol in `P` is considered
a binding name. `:autobinding{P}`\\`:A{P}` removes the `:literal`
effect.

"""
Binding;

"""

`EqualityCheck` is a `PatternCheck` that tests
if an expression is equal to some value.

"""
EqualityCheck;

"""
`TypeCheck` is a `PatternCheck` that tests
if an expression is of some type.

"""
TypeCheck;

"""
`PredicateCheck` is a `PatternCheck` that tests
if an expression fulfills some predicate.

"""
PredicateCheck;


"""
`ArgsStep` is a `PatternStep` that extracts
the arguments from a expression unmodified.

"""
ArgsStep;

"""
`BlockStep` is a `PatternStep` that extracts
the non-line-number arguments from a expression.

"""
BlockStep;

"""
`QuoteStep` is a `PatternStep` that extracts
the value of a `QuoteNode` or the arguments
from a `:quote` expression.

"""
QuoteStep;

"""
Since slurps already work with extracted
arguments, there is no need for a step for
them. Calling `SlurpStep` causes an error.

"""
SlurpStep;

#-----------------------------------------------------------------------------------
# PatternStructure.SlurpTypes;
#-----------------------------------------------------------------------------------
import ..PatternStructure.SlurpTypes: SlurpHead, LazySlurp, GreedySlurp,
                                      GenericGreedySlurp, GenericLazySlurp

"""
Represents a slurp algorithm. Can be a `LazySlurp` or a `GreedySlurp`, and
many variations of each.

Subtypes:
- `LazySlurp`
- `GreedySlurp`
- `GenericLazySlurp`
- `GenericGreedySlurp`

"""
SlurpHead;

"""
Match as many arguments as possible, then try
to match the rest of pattern, putting back
arguments from the slurp if neccessary.

"""
LazySlurp;

"""
Only try to match the slurp if the pattern after it
can't match the expression.

"""
GreedySlurp;

"""
Slowest version of a `LazySlurp`, but works for any pattern.

"""
GenericLazySlurp;

"""
Slowest version of a `GreedySlurp`, but works for any pattern.

"""
GenericGreedySlurp;
