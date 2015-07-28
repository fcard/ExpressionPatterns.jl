#-----------------------------------------------------------------------------------
# Analyzer.Function;
#-----------------------------------------------------------------------------------
import ..Analyzer.Function: getstep, is_binding_name, is_special_expr, assertation_args,
                            AnalysisState, analyze, analyze!, analyze_args!

"""
`analyze(ex[, module]) -> PatternRoot`

Parses a julia code expression into a `PatternTree`, which
can be used in matching, destructuring and dispatch.

See [Language.md](../../Language.md) for an overview
on how to construct patterns.

This function also receives an module that will be
used in `evals`, for example in

```julia
analyze(:(:T{MyType}), MyModule)
```

`MyType` will be looked for in `MyModule`.
If no module is specified, `current_module` is used.

"""
analyze;

"""
`analyze!(ex, state::AnalysisState)`

Used by `analyze`, this creates a `PatternTree` from `ex`
and inserts them in the tree in `state`.

"""
analyze!;

"""
`analyze_args!(args, node, state)`

Analyzes the arguments of an expression (`args`) to
create the children of the `PatternNode` `node`.

Calls the slurp optimizations function (`optimize_slurps!`) when done.

"""
analyze_args!;

"""
`getstep(head::Symbol) -> PatternStep`

Get the `PatternStep` that should be used with
expressions of the given `head`.

| head     | step        |
|:---------|:------------|
| `:quote` | `QuoteStep` |
| `:block` | `BlockStep` |
| other    | `ArgsStep`  |

"""
getstep;

"""
`is_binding_name(sym) -> Bool`

Determines if `sym` is to be automatically considered
a binding name. Returns `true` if `sym` starts with a
letter, `#` or `@`.

"""
is_binding_name;

"""
`is_special_expr(ex) -> Bool`

Checks if `ex` is of the form `:X{ys...}` or `(*\\?){ys...}` and thus
represents a special pattern.

Related:
- `PatternCheck`

"""
is_special_expr;

"""
`assertation_args(expr_args) -> Vector`

This converts the one argument form of the a pattern
check to the two arguments form.

If `expr_args` is a vector of one element, that means
that a pattern of the form `:X{Y}` was passed, which is equivalent
to `:X{p,Y}` where `p` is a symbol. Adds one symbol to
the `expr_args`.

If `expr_args` is a vector of two elements, than a pattern
like `:X{P,Y}` was passed. Returns `expr_args` as is.

"""
assertation_args;

"""
`AnalysisState` keeps track of the current pattern tree
being matched, whether the literal mode is active or not,
and the module that is to be used in `eval`s.

"""
AnalysisState;

#-----------------------------------------------------------------------------------
# Analyzer.SlurpOptimizations;
#-----------------------------------------------------------------------------------
import ..Analyzer.SlurpOptimizations: optimize_slurps!

"""
`optimize_slurps!(node)`

Starting from the last, replaces the generic slurp algorithms
with faster ones, if possible.

"""
optimize_slurps!;
