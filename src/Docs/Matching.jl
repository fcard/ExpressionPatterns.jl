#-----------------------------------------------------------------------------------
# Matching.Consistency;
#-----------------------------------------------------------------------------------
import ..Matching.Consistency: Variables, match_variable!, unmatch_variable!

"""
  Variables(vars::Set{Symbol}) creates an environment that
  can be used to check the consistency of pattern variables.
  Use match_variable!(vars, name, value) to do so.

"""
Variables;

"""
`match_variable!(vars::Variables, name::Symbol, val) -> Bool`

Tries to match the pattern variable `name`
(as defined in `vars`) with `val`.  
If the variable is not defined in vars, then the
variable is mutable and the match returns true.  
If the variable has no value, attribute `val` to
it and return true.  
If the variable has a value `val`, then the match is true
if and only if `val` is that value.

"""
match_variable!;

"""
`unmatch_variable!(vars::Variables, name::Symbol)`

Undoes a match. If the variable was matched `n` times with
a value `val`, unmatching `n` times will remove `val` from
the variable, allowing it to be matched by another value.

"""
unmatch_variable!;

#-----------------------------------------------------------------------------------
# Matching.Function;
#-----------------------------------------------------------------------------------
import ..Matching.Function: exprhead, matcher

"""
`exprhead(ex) -> Symbol`

Returns `:quote` if `ex` is a `QuoteNode`, `ex.head` if
`ex` is an `Expr`, and `notexpr` for anything else.  
Used to simplify algorithms by having `QuoteNode`s be
treated as `Expr`s with one argument.

"""
exprhead;

"""
`matcher(pattern) -> (ex) -> Bool`

Given a pattern `P`, creates a `match` function that will tell
if an expression is matched by `P`. See [Language.md](../../Language.md)
to learn to create patterns.

examples:
```julia
match_anything = matcher(:x)  
match_addition = matcher(:(x+y))  
match_forloop  = matcher(:(for x=coll; body... end))  
match_9s_tuple = matcher(:(*{9},)) # e.g. (9,9), (9,9,9,9,9), ()  
# more examples in the tests

```

"""
matcher;

#-----------------------------------------------------------------------------------
# Matching.Comparison;
#-----------------------------------------------------------------------------------
import ..Matching.Comparison: conflicts, compare_trees

"""
`compare_trees(a::PatternTree, b::PatternTree) -> Symbol`

Compare two pattern trees `a` and `b` and return
a symbol that describes their relationship.

`:equal` means `a` and `b` match the exact same set of expressions.
can be checked with `a == b`.


`:unequal` means `a` and `b` matches disjoint sets of expressions.
Can be checked with `a != b`.

`:superset` means `a` matches all expressions that `b` match.
Can be checked with `a ⊇ b`.

`:subset` means `b` matches all expressions that `a` match.
Can be checked with `a ⊆ b`.

`:conflicts` means that there is a intersection between the sets of expressions `a` and `b` match,
but `a` also matches some expressions that `b` don't, and virce versa. Can be checked with `conflicts(a,b)`.

"""
compare_trees;


"""
`conflicts(a::PatternTree, b::PatternTree) -> Bool`

Uses `compare_trees` to check if `a` conflicts with `b`.

"""
conflicts;