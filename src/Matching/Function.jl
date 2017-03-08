module Function
using  ...Analyzer.Function
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
using  ...PatternStructure.Special
using  ...Matching.Environment
using  ...Helper
export matcher

function matcher(pattern, mod=current_module())
  const pattern_tree = analyze(pattern, mod).child

  return match!(ex, variables=Variables()) =
    matchtree(pattern_tree, ex, newstate(variables))
end

struct MatchState
  inslurp     :: Bool
  variables   :: Variables
  slurpranges :: SlurpRanges
end
newstate(vars)    = MatchState(false, vars, SlurpRanges())
enterslurp(state) = MatchState(true, state.variables, SlurpRanges())

struct SlurpInfo
  node        :: PatternNode
  parent      :: PatternTree
  children    :: Vector
  position    :: Int
  starting_ai :: Int
  parentstate :: MatchState
  state       :: MatchState
end

#----------------------------------------------------------------------------
# matchtree: Tries to match the expression with a pattern tree.
#----------------------------------------------------------------------------

matchtree(leaf::PatternLeaf, ex, st) = true

function matchtree(gate::PatternGate, ex, st)
  match_check(gate.check, ex, st) &&
    matchtree(gate.child, ex, st)
end

function matchtree(node::PatternNode, ex, st)
  exprhead(ex) == nodehead(node) || return false

  args = node.step(ex)
  match_children(node, args, 1, 1, st)
end

#----------------------------------------------------------------------------
# match_check: matches a pattern check with an expression.
#----------------------------------------------------------------------------

function match_check(bd::Binding, ex, st)
  st.inslurp? true :  match_variable!(st.variables, bd.name, ex)
end

match_check{T}(check::EqualityCheck{T}, ex::T, st) = check.value == ex
match_check{T}(check::TypeCheck{T},     ex::T, st) = true
match_check(check::PredicateCheck,      ex,    st) = check.predicate(ex)

match_check(check, ex, st) = false


#----------------------------------------------------------------------------
# match_children: matches a vector of patterns with a vector of expressions.
#----------------------------------------------------------------------------

function match_children(node, args, ci, ai, st)
  matches = true

  for cj in ci:endof(node.children)
    matches  || return false
    matches, ai = match_child(node, args, cj, ai, false, st)
  end
  return matches && ai > length(args)
end

function match_child(node, args, ci, ai, slurpchild, st)
  is_slurp(node.children[ci])?
    (match_slurp(node, args, ci, ai, slurpchild, st)) :
    (match_nonslurp_child(node, args, ci, ai, st), ai+1)
  #end
end

function match_nonslurp_child(node, args, ci, ai, st)
  ai <= length(args) &&
  matchtree(node.children[ci], args[ai], st)
end

#----------------------------------------------------------------------------
# slurps: Patterns of the form (P...). Can be matched greedily or lazily.
#----------------------------------------------------------------------------

function match_slurp(node, args, ci, ai, slurpchild, st)
  slurpchild && match_directly_nested_slurp(node)

  local matches, mi

  slurp  = node.children[ci]
  mstate = st.inslurp? st : enterslurp(st)

  if ai <= length(args)
     s_info = SlurpInfo(slurp, node, slurp.children, ci, ai, st, mstate)
     matches, mi = match_slurp_impl(slurp.head, s_info, args)
  else
    matches = true
    mi = ai
  end


  if matches
    add_slurp_range!(st.slurpranges, slurp, ai:mi-1)

    if !st.inslurp
      extract!(mstate.variables, slurp, args, ai, mi-1, mstate.slurpranges)
    end
  end

  matches, mi
end

#----------------------------------------------------------------------------

function match_after_slurp(slurp, args, ai)
  match_children(slurp.parent, args, slurp.position+1, ai, slurp.parentstate)
end

function match_as_many_as_possible(slurp, args)
  mi       = slurp.starting_ai # match index
  args_len = length(args)
  matches  = true

  while matches && mi <= args_len
    oldmi = mi
    for ci in eachindex(slurp.children)
      matches || break
      matches, mi = match_child(slurp.node, args, ci, mi, true, slurp.state)
    end
    !matches && begin mi = oldmi end
  end
  return mi
end

function put_back_until_match(slurp, args, mi)
  match_size = length(slurp.children)
  matches    = false

  while slurp.starting_ai < mi && !matches
    matches =  match_after_slurp(slurp, args, mi)
    matches || begin mi -= match_size end
  end
  return mi, matches
end

function match_slurp_impl(::GenericGreedySlurp, slurp, args)
  mi = match_as_many_as_possible(slurp, args)
  mi, matches = put_back_until_match(slurp, args, mi)

  return (mi == slurp.starting_ai || matches), mi
end

#----------------------------------------------------------------------------

function match_slurp_impl(::GenericLazySlurp, slurp, args)
  match_size  = length(slurp.children)
  args_length = length(args)

  mi = slurp.starting_ai
  while !(match_after_slurp(slurp, args, mi))
    for ci in eachindex(slurp.children)
      matches, mi = match_child(slurp.node, args, ci, mi, true, slurp.state)
      matches || return false, 0
    end
  end
  return true, mi
end

#----------------------------------------------------------------------------

function match_slurp_impl(h::SimpleLastSlurp, slurp, args)
  return length(args)>=h.post, length(args)-h.post+1
end

#----------------------------------------------------------------------------

function slurp_until(found, slurp, args, si)
  ai = slurp.starting_ai
  ci = slurp.position
  st = slurp.parentstate

  found      = filter(x->x>=ai+si-1, found)
  matches(f) = match_children(slurp.parent, args, ci+1, f[1]-si+1, st)

  while !isempty(found) &&
        !matches(found)
    found = found[2:end]
  end
  return !isempty(found), isempty(found)? 0 : found[1]-si+1
end

function match_slurp_impl(h::SimpleGreedySlurpUntil, slurp, args)
  slurp_until(reverse(findin(args, h.until)), slurp, args, h.index)
end


function match_slurp_impl(h::SimpleLazySlurpUntil, slurp, args)
  slurp_until(findin(args, h.until), slurp, args, h.index)
end

#----------------------------------------------------------------------------

match_nested_slurp(node) =
  error("Nesting slurps in another slurp's arguments isn't supported. (found in $(node))")

#----------------------------------------------------------------------------
# Utility functions
#----------------------------------------------------------------------------

const Iterable = Union{Vector, Tuple}

exprhead(ex::Expr)      = ex.head in [:kw, :(=)]? :assign : ex.head
exprhead(ex::QuoteNode) = :quote
exprhead(ex::Iterable)  = :iterable
exprhead(ex::Any)       = :notexpr

#----------------------------------------------------------------------------
end
