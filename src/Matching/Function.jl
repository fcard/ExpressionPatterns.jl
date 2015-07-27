module Function
using  ...Analyzer.Function
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
using  ...PatternStructure.Special
using  ...Matching.Consistency
using  ...Helper
export matcher

function matcher(pattern, mod=current_module())
  const pattern_tree = analyze(pattern, mod).child
  const pattern_vars = constants(pattern_tree)

  return match(ex) =
    matchtree(pattern_tree, ex, Variables(pattern_vars))
end

@implicit variables begin

#----------------------------------------------------------------------------
# matchtree: Tries to match the expression with a pattern tree.
#----------------------------------------------------------------------------

  function matchtree(leaf::PatternLeaf, ex)
    return true
  end

  function matchtree(gate::PatternGate, ex)
    match_check(gate.check, ex) &&
    matchtree(gate.child, ex)
  end

  function matchtree(node::PatternNode, ex)
    exprhead(ex) == nodehead(node) || return false

    args = node.step(ex)
    match_children(node, args, 1, 1)
  end

#----------------------------------------------------------------------------
# match_check: matches a pattern check with an expression.
#----------------------------------------------------------------------------

  # the one use of the `variables` implicit parameter.
  match_check(bd::Binding, ex) = match_variable!(variables, bd.name, ex)

  match_check{T}(check::EqualityCheck{T}, ex::T) = check.value == ex
  match_check{T}(check::TypeCheck{T},     ex::T) = true
  match_check(check::PredicateCheck,      ex)    = check.predicate(ex)

  match_check(chk, ex) = false


#----------------------------------------------------------------------------
# match_children: matches a vector of patterns with a vector of expressions.
#----------------------------------------------------------------------------

  function match_children(node, args, i, pos)
    local matches = true

    for j in i:endof(node.children)
      matches || return false
      matches, pos = match_child(node, args, j, pos, false)
    end
    return matches && pos > length(args)
  end

  function match_child(node, args, i, pos, slurp)
    is_slurp(node.children[i])?
      (slurp? match_nested_slurp(node) :
              match_slurp(node, args, i, pos)) :
      (match_nonslurp_child(node, args, i, pos), pos+1)
  end

  function match_nonslurp_child(node, args, i, pos)
    pos <= length(args) &&
    matchtree(node.children[i], args[pos])
  end
#----------------------------------------------------------------------------
# slurps: Patterns of the form (P...). Can be matched greedily or lazily.
#----------------------------------------------------------------------------

  function match_slurp(node, args, sp, pos)
    pos > length(args) && return true, pos

    slurp = node.children[sp]
    match_slurp_impl(slurp.head, node, slurp, sp, args, pos)
  end

#----------------------------------------------------------------------------
  function match_slurp_impl(::GenericGreedySlurp, node, slurp, sp, args, pos)
    match_size  = length(slurp.children)
    args_length = length(args)

    mpos    = pos # match position
    matches = true

    while matches && mpos <= args_length
      oldmpos = mpos
      for i in eachindex(slurp.children)
        matches || break
        matches, mpos = match_child(slurp, args, i, mpos, true)
      end
      !matches && begin mpos = oldmpos end
    end

    matches = false
    while pos < mpos && !matches
      matches = match_children(node, args, sp+1, mpos)
      if !matches
         mpos -= match_size
         unmatch_variable!(variables, constants(slurp))
      end
    end

    return (mpos == pos || matches), mpos
  end

#----------------------------------------------------------------------------
  function match_slurp_impl(::GenericLazySlurp, node, slurp, sp, args, pos)
    match_size  = length(slurp.children)
    args_length = length(args)

    mpos = pos
    while !(match_children(node, args, sp+1, mpos))
      for i in eachindex(slurp.children)
        matches, mpos = match_child(slurp, args, i, mpos, true)
        matches || return false, 0
      end
    end
    return true, mpos
  end

#----------------------------------------------------------------------------
  function match_slurp_impl(h::SimpleLastSlurp, node, slurp, sp, args, pos)
    return length(args)>=h.post, length(args)-h.post+1
  end
#----------------------------------------------------------------------------
end

match_nested_slurp(node) =
  error("Nesting slurps in another slurp's arguments isn't supported. (found in $(node))")

#----------------------------------------------------------------------------
# Utility functions
#----------------------------------------------------------------------------

typealias Iterable Union{Vector, Tuple}

exprhead(ex::Expr)      = ex.head in [:kw, :(=)]? :assign : ex.head
exprhead(ex::QuoteNode) = :quote
exprhead(ex::Iterable)  = :iterable
exprhead(ex::Any)       = :notexpr

#----------------------------------------------------------------------------
end
