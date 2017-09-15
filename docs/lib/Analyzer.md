Analyzer.Function
==========

#### analyze

`analyze(ex[, module]) -> PatternRoot`

Parses a julia code expression into a [`PatternTree`](./PatternStructure.md#patterntree), which
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

---
#### analyze!

`analyze!(ex, state::AnalysisState)`

Used by [`analyze`](./Analyzer.md#analyze), this creates a [`PatternTree`](./PatternStructure.md#patterntree) from `ex`
and inserts them in the tree in `state`.

---
#### analyze_args!

`analyze_args!(args, node, state)`

Analyzes the arguments of an expression (`args`) to
create the children of the [`PatternNode`](./PatternStructure.md#patternnode) `node`.

Calls the slurp optimizations function ([`optimize_slurps!`](./Analyzer.md#optimize_slurps!)) when done.

---
#### getstep

`getstep(head::Symbol) -> PatternStep`

Get the [`PatternStep`](./PatternStructure.md#patternstep) that should be used with
expressions of the given `head`.

| head     | step        |
|:---------|:------------|
| `:quote` | [`QuoteStep`](./PatternStructure.md#quotestep) |
| `:block` | [`BlockStep`](./PatternStructure.md#blockstep) |
| other    | [`ArgsStep`](./PatternStructure.md#argsstep)  |

---
#### is_special_expr

`is_special_expr(ex) -> Bool`

Checks if `ex` is of the form `:X{ys...}` or `(*\?){ys...}` and thus
represents a special pattern.

Related:
- [`PatternCheck`](./PatternStructure.md#patterncheck)

---
#### assertation_args

`assertation_args(expr_args) -> Vector`

This converts the one argument form of the a pattern
check to the two arguments form.

If `expr_args` is a vector of one element, that means
that a pattern of the form `:X{Y}` was passed, which is equivalent
to `:X{p,Y}` where `p` is a symbol. Adds one symbol to
the `expr_args`.

If `expr_args` is a vector of two elements, than a pattern
like `:X{P,Y}` was passed. Returns `expr_args` as is.

---
#### AnalysisState

`AnalysisState` keeps track of the current pattern tree
being matched, whether the literal mode is active or not,
and the module that is to be used in `eval`s.

---


Analyzer.SlurpOptimizations
==========

#### optimize_slurps!

`optimize_slurps!(node)`

Starting from the last, replaces the generic slurp algorithms
with faster ones, if possible.

---


