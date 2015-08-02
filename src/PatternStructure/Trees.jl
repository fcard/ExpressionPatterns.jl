module Trees
export PatternTree, PatternStep, PatternCheck,
       PatternLeaf, PatternNode, PatternGate,
       PatternRoot, PatternHead, Binding,

       ExprHead, SlurpHead,

       nodehead, bindings, insert!, newnode!,
       newleaf!, slicenode, depth

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
  bindings :: Set{Symbol}
  depth    :: Int
end

immutable PatternLeaf <: PatternTree
end

immutable Binding <: PatternCheck
  name::Symbol
end

type PatternGate <: PatternTree
  check    :: PatternCheck
  bindings :: Set{Symbol}
  depth    :: Int
  child    :: PatternTree

  PatternGate(check::Any,     depth) = new(check, Set{Symbol}(), depth)
  PatternGate(check::Binding, depth) = new(check, Set{Symbol}([check.name]), depth)
end

abstract SlurpHead <: PatternHead

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

bindings(leaf::PatternLeaf) = Set{Symbol}()
bindings(root::PatternRoot) = bindings(root.child)
bindings(gate::PatternGate) = gate.bindings
bindings(node::PatternNode) = node.bindings

depth(root::PatternRoot) = 0
depth(gate::PatternGate) = gate.depth
depth(node::PatternNode) = node.depth

function makenode(head, step, depth)
  children   = PatternTree[]
  bindings   = Set{Symbol}()
  slurpdepth = isa(head, SlurpHead)? depth+1 : depth

  PatternNode(head, step, children, bindings, slurpdepth)
end

import Base: insert!

function insert!(parent::PatternNode, child)
  push!(parent.children, child)
  union!(parent.bindings, bindings(child))
end

function insert!(parent::PatternGate, child)
  parent.child = child
  union!(parent.bindings, bindings(child))
end

function insert!(parent::PatternRoot, child)
  parent.child = child
end

function newnode!(head, step, parent::PatternTree)
  node = makenode(head, step, depth(parent))
  insert!(parent, node)
  return node
end

function newnode!(check, head, step, parent::PatternTree)
  node = makenode(head, step, depth(parent))
  gate = PatternGate(check, depth(parent))
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
  gate = PatternGate(check, depth(parent))
  insert!(gate, leaf)
  insert!(parent, gate)
  return leaf
end

function slicenode(node::PatternNode, range)
  fst,lst = first(range), last(range)
  head = node.head
  step = node.step
  children = node.children[fst:lst]
  binds    = mapreduce(bindings, union, Set{Symbol}(), children)

  PatternNode(head, step, children, binds, node.depth)
end

#-----------------------------------------------------------------------------------
end
