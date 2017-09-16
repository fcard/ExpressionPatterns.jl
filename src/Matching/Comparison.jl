module Comparison
using  ...Matching.Environment
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.Special
using  ...PatternStructure.SlurpTypes
import Base: ==, ⊆, ⊇ ;
export compare_trees, conflicts, ⊇;

==(a::PatternTree, b::PatternTree) = compare_trees(a,b) == :equal
 ⊇(a::PatternTree, b::PatternTree) = compare_trees(a,b) in [:equal, :superset]
 ⊆(a::PatternTree, b::PatternTree) = compare_trees(a,b) in [:equal, :subset]

conflicts(a::PatternTree, b::PatternTree) = compare_trees(a,b) == :conflicts

abstract type PatternData{P} end

mutable struct PatternNodeData{P,N} <: PatternData{P}
  pattern::P
  index::Int
  repeats::N
  real_length::Int
end

struct PatternGenericData{P} <: PatternData{P}
  pattern::P
end

PatternData(p::PatternNode, args...) = PatternNodeData(p, args...)
PatternData(p) = PatternGenericData(p)

struct PatternCmp{P<:Union{PatternTree, PatternCheck}}
  data::PatternData{P}
  vars::Variables
  freeze::Bool

  function PatternCmp(p::P, vars=Variables(), freeze=false, repeats=1) where P <: PatternNode
    new{P}(PatternNodeData(p, 1, repeats, length(p.children)), vars, freeze)
  end

  function PatternCmp(p::P, vars=Variables(), freeze=false) where P
    new{P}(PatternGenericData(p), vars, freeze)
  end

  function PatternCmp(d::PatternData{P}, vars, freeze=false) where P
    new{P}(d, vars, freeze)
  end
end

pattern(p::PatternCmp) = p.data.pattern

macro cmp(a::Union{Expr,Symbol})
  @assert a isa Symbol || a.head == :.

  let root, fields_f
    dotroot(x::Expr, f=identity)   = dotroot(x.args[1], y->(Expr(:., y, f(x.args[2]))))
    dotroot(x::Symbol, f=identity) = x, y->f(:($x.data.pattern))

    root, fields_f = dotroot(a)

    esc(:($PatternCmp($(fields_f(root)), $root.vars, $root.freeze)))
  end
end

const PC = PatternCmp

Base.isempty(p::PC{PatternNode{H}}) where H =
  isempty(pattern(p).children)

real_length(p::PC{P}) where P <: PatternNode =
  length(pattern(p).children)

Base.length(p::PC{P}) where P <: PatternNode =
  real_length(p)*p.data.repeats

finished(p::PC{P}) where P <: PatternNode =
  p.data.index > length(p)

getchild(p::PC{P}) where P <: PatternNode =
  finished(p) ?
    throw(BoundsError(pattern(p).children, p.data.index)) :
    PatternCmp(pattern(p).children[max(1, p.data.index%(p.data.real_length+1))], p.vars, is_slurp(pattern(p)) || p.freeze)

function setchild!(p::PC{P}, i) where P <: PatternNode
  p.data.index = i
end

function next_child!(p::PC{P}) where P <: PatternNode
  p.data.index += 1
end

repeat(p::PatternCmp, repeats::Union{Int, Float64}) =
  PatternCmp(PatternData(pattern(p), p.data.index, repeats, real_length(p)), p.vars)


compare_trees(a::PatternTree, b::PatternTree) =
  compare_trees(PatternCmp(a), PatternCmp(b))

compare_trees(a::PC{PatternRoot}, b::PC{PatternRoot}) =
  compare_trees(@cmp(a.child), @cmp(b.child))

compare_trees(a::PC{PatternNode{H1}}, b::PC{PatternNode{H2}}) where {H1,H2} =
  compatible_heads(pattern(a).head, pattern(b).head) ?
    compare_children(a, b) : :unequal

function compare_children(a, b)
  if isempty(a)
    if isempty(b)
      return :equal
    else
      reverse_comparison_result(compare_children(b, a))
    end
  else
    let result=:equal, onfailure=Tuple{Int,Int,Symbol}[]
      while true

        if !finished(a) && !finished(b)
          result = update_result(result, compare_child(a, b, onfailure))

        elseif !finished(a)
          result = is_slurp(pattern(getchild(a))) ? update_result(result, :superset) : :unequal
          next_child!(a)

        elseif !finished(b)
          result = is_slurp(pattern(getchild(b))) ? update_result(result, :subset) : :unequal
          next_child!(b)

        else
          return result
        end

        if result in (:conflicts, :unequal)
          if isempty(onfailure)
            return result
          else
            a_index, b_index, result = pop!(onfailure)
            setchild!(a, a_index)
            setchild!(b, b_index)
          end
        end
      end
    end
  end
end

function compare_child(a, b, onfailure)
  ca = getchild(a)
  cb = getchild(b)

  isla, islb = is_slurp(pattern(ca)), is_slurp(pattern(cb))

  if isla && islb
    let result = compare_slurps(ca, cb)
      if result in (:equal, :subset, :superset)
        push!(onfailure, (a.data.index, b.data.index+1, :superset))
        push!(onfailure, (a.data.index+1, b.data.index, :subset))
        next_child!(a)
        next_child!(b)
        return result
      else
        return :unequal
      end
    end
  elseif isla
    ca = repeat(ca, Inf)
    while !finished(b) && compare_trees(getchild(ca), getchild(b)) in (:superset, :equal)
      push!(onfailure, (a.data.index+1, b.data.index, :superset))
      next_child!(ca)
      next_child!(b)
    end
    next_child!(a)
    return :superset

  elseif islb
    let rev_onfailure=Tuple{Int,Int,Symbol}[]
      compare_child(b, a, rev_onfailure)
      for onf in rev_onfailure
        push!(onfailure, (onf[2], onf[1], reverse_comparison_result(onf[3])))
      end
      return :subset
    end
  else
    next_child!(a)
    next_child!(b)
    compare_trees(ca, cb)
  end
end

function compare_slurps(a, b)
  if compatible_heads(pattern(a).head, pattern(b).head)
    if real_length(a) == real_length(b)
      compare_children(a, b)

    elseif (real_length(a) % real_length(b)) == 0
      res = compare_children(a, repeat(b, div(real_length(a), real_length(b))))
      res == :equal ? :superset : res

    elseif (real_length(b) % real_length(a)) == 0
      reverse_comparison_result(compare_slurps(b, a))

    else
      return :unequal
    end
  else
    return :unequal
  end
end

function compare_trees(a::PC{PatternGate}, b::PC{PatternGate})
  checks =  compare_checks(@cmp(a.check), @cmp(b.check))
  checks == :equal ?
    compare_trees(@cmp(a.child), @cmp(b.child)) : checks
end

function compare_trees(a::PC{PatternGate}, b)
  checks =  compare_checks(@cmp(a.check), b)
  checks == :superset ? :superset : :unequal
end

function compare_trees(a, b::PC{PatternGate})
  checks =  compare_checks(a, @cmp(b.check))
  checks == :subset ? :subset : :unequal
end

compare_checks(a::PC{Binding}, b::PC{Binding}) =
  a.freeze ? check_frozen_variable(a, b) :
  b.freeze ? check_frozen_variable(b, a) :
  match_variable!(a.vars, pattern(a).name, pattern(b).name) &&
  match_variable!(b.vars, pattern(b).name, pattern(a).name)  ? :equal : :unequal

compare_checks(a::PC{Binding}, b) =
  a.freeze ? check_frozen_variable(a, b) : check_and_match_variable(a, b)

compare_checks(a, b::PC{Binding}) = reverse_comparison_result(compare_checks(b, a))

check_frozen_variable(a, b) =
  !haskey(a.vars, pattern(a).name) || a.vars[pattern(a).name] == pattern(b) ? :superset : :unequal

check_and_match_variable(a, b) =
  match_variable!(a.vars, pattern(a).name, pattern(b)) ? :superset : :unequal

compare_checks(a::PC{EqualityCheck{T}}, b::PC{EqualityCheck{T}}) where T =
  pattern(a).value == pattern(b).value ? :equal : :unequal

compare_checks(a::PC{PredicateCheck}, b::PC{PredicateCheck}) =
  pattern(a).predicate == pattern(b).predicate ? :equal : :unequal

compare_checks(a::PC{TypeCheck{T1}}, b::PC{TypeCheck{T2}}) where {T1, T2} =
  T1 == T2 ? :equal    :
  T2 <: T1 ? :superset :
  T1 <: T2 ? :subset   :
             :unequal

compare_checks(a, b) = :unequal

compare_trees(a::PC{PatternLeaf}, b::PC{PatternLeaf}) = :equal
compare_trees(a, b) = :unequal

update_result(final, result) =
  result == :equal   ? final    :
  final  == :equal   ? result   :
  final  == :unequal ? :unequal :
  (result == :subset   && final == :superset) ||
  (result == :superset && final == :subset)   ?
    :conflicts : result


reverse_comparison_result(res) = res == :superset ? :subset : res == :subset ? :superset : res

compatible_heads(x::H, y::H) where H = x == y
compatible_heads(::S1, ::S2) where {S1 <: LazySlurp,   S2 <: LazySlurp}   = true
compatible_heads(::S1, ::S2) where {S1 <: GreedySlurp, S2 <: GreedySlurp} = true
compatible_heads(a,b) = false


end
