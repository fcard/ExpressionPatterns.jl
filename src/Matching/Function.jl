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
  variables::Variables
end
newstate(vars) = MatchState(vars)

struct ChildrenState{T}
  variables::Variables
  depths::Dict{Symbol, Int}
  depth::Int
  exprs::Vector{Any}
  tree_children::Vector{T}
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

  children = node.step(ex)
  match_children(node, children, st)
end

#----------------------------------------------------------------------------
# match_check: matches a pattern check with an expression.
#----------------------------------------------------------------------------

function match_check(bd::Binding, ex, st::MatchState)
  if haskey(st.variables, bd.name)
    st.variables[bd.name] == ex
  else
    st.variables[bd.name] = ex
    true
  end
end

function match_check(bd::Binding, ex, st::ChildrenState)
  if haskey(st.depths, bd.name)
    st.depths[bd.name] == st.depth
  else
    st.depths[bd.name] = st.depth
    true
  end
end

match_check(check::EqualityCheck{T}, ex::T, st) where T = check.value == ex
match_check(check::TypeCheck{T},     ex::T, st) where T = true
match_check(check::PredicateCheck,   ex,    st) = check.predicate(ex)

match_check(check, ex, st) = false

#----------------------------------------------------------------------------
# match_children: matches a vector of patterns with a vector of expressions.
#----------------------------------------------------------------------------

function match_children(node, exprs, st)
  s = PatternStream(st, node.children, exprs)
  match_ranges!(s) && match_with_ranges(s)
end

#-------------------------------------------------------------------------------------------
# find_matching_indexes: Map the indexes of the children of a pattern tree and a expression
#-------------------------------------------------------------------------------------------

const SLURP_MATCHING_FUNCTIONS = Dict{DataType, Function}()

function match_ranges(s)
  if next_pattern_type(s) <: SlurpHead
    SLURP_MATCHING_FUNCTIONS[next_pattern_type(s)](s)
  else
    match_nonslurp_child(s)
  end
end

function match_nonslurp_child(s)
  matchtree(get_pattern!(s), get_expr!(s), state(s))
end

SLURP_MATCHING_FUNCTIONS[GenericGreedySlurp] = function(s)
  endpoint = expr_length(s)
  while !done(s) && 


end

function find_matching_indexes(node::PatternNode{S}, cst) where S <: LazySlurp
  
end

function find_matching_indexes(tree_index, expr_index, cst)
  find_matching_indexes(cst.tree_children[tree_index], tree_index, expr_index, cst)
end

function find_matching_indexes(node::PatternNode{S}, tree_index, expr_index, cst) where S <: LazySlurp
  endpoint = expr_index
  while endpoint <= length(cst.exprs) && !find_matching_indexes(tree_index+1, endpoint, cst)
    match_slurp(node, endpoint, cst) || return false
    endpoint += length(tree.children)
  end
  endpoint <= length(cst.exprs)
end

function find_matching_indexes(node::PatternNode{S}, tree_index, expr_index, cst) where S <: GreedySlurp
  endpoint = lentgh(cst.exprs)
  while endpoint >= expr_index && find_matching_indexes(tree_index+1, endpoint, cst)
    all(cst.exprs[expr_index:length(node.children):endpoint]) do i
      match_slurp(

    match_slurp(tree, endpoint, cst) || return false
    endpoint += 1
  end
  endpoint <= length(cst.exprs)
end

function match_slurp(tree, i, cst)
  all(eachindex(tree.children)) do j
    match_check(tree.children[j], cst.exprs[i+j-1], cst)
  end
end

function find_matching_indexes(tree::PatternNode{S}, tree_index, expr_index, cst) where S <: LazySlurp
  next_expr_index = expr_index
  while match_slurp(tree, cst) && !find_matching_indexes(tree_index+1, next_expr_index, cst)
    next_expr_index += 1
  end
end

function find_matching_indexes(tree
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

jfunction match_slurp(node, args, ci, ai, slurpchild, st)
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
