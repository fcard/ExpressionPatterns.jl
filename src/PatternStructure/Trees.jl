module Trees
export PatternTree, PatternStep, PatternCheck,
       PatternLeaf, PatternNode, PatternGate,
       PatternRoot, PatternHead, ExprHead,
       nodehead, constants, insert!, newnode!,
       newleaf!, slicenode

#-----------------------------------------------------------------------------------
# Type definitions
#-----------------------------------------------------------------------------------

abstract PatternTree
abstract PatternStep
abstract PatternCheck
abstract PatternHead

type PatternRoot <: PatternTree
  child::PatternTree
  PatternRoot() = new()
end

immutable PatternNode <: PatternTree
  head     :: PatternHead
  step     :: PatternStep
  children :: Vector{PatternTree}
  consts   :: Set{Symbol}
end

immutable PatternLeaf <: PatternTree
end

type PatternGate <: PatternTree
  check  :: PatternCheck
  consts :: Set{Symbol}
  child  :: PatternTree

  PatternGate(check) = new(check, Set{Symbol}())
end

immutable ExprHead <: PatternHead
  sym::Symbol
end

typealias SingleChildNode Union{PatternGate, PatternRoot}

#-----------------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------------

function nodehead(node::PatternNode)
  isa(node.head, ExprHead)? node.head.sym : (:slurp)
end

constants(leaf::PatternLeaf) = Set{Symbol}()
constants(root::PatternRoot) = constants(root.child)
constants(gate::PatternGate) = gate.consts
constants(node::PatternNode) = node.consts

function makenode(head, step)
  children = PatternTree[]
  consts   = Set{Symbol}()
  PatternNode(head, step, children, consts)
end

import Base: insert!

function insert!(parent::PatternNode, child)
  push!(parent.children, child)
end

function insert!(parent::SingleChildNode, child)
  parent.child = child
end

function insert!(parent::PatternRoot, child)
  parent.child = child
end

function newnode!(head, step, parent::PatternTree)
  node = makenode(head, step)
  insert!(parent, node)
  return node
end

function newnode!(check, head, step, parent::PatternTree)
  node = makenode(head, step)
  gate = PatternGate(check)
  insert!(gate, node)
  insert!(parent, gate)
  return node
end

function newleaf!(parent::PatternTree)
  leaf = PatternLeaf()
  insert!(parent, leaf)
  return leaf
end

function newleaf!(check, parent::PatternTree)
  leaf = PatternLeaf()
  gate = PatternGate(check)
  insert!(gate, leaf)
  insert!(parent, gate)
  return leaf
end

function slicenode(node::PatternNode, range)
  fst,lst = first(range), last(range)
  head = node.head
  step = node.step
  children = node.children[fst:lst]
  consts   = mapreduce(constants, union, Set{Symbol}(), children)

  PatternNode(head, step, children, consts)
end

#-----------------------------------------------------------------------------------
end
