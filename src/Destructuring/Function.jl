module Function
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.Special
using  ...Destructuring.Structure
using  ...Destructuring.CodeGeneration
using  ...Destructuring.Slurps
import ...Analyzer.Function: analyze
import ...Matching.Function: matchtree, match_children
import ...Matching.Consistency: Variables, unmatch_variable!
import ...Helper: clean_code
import Base.Meta: quot
export destructure

function destructure(pattern, ex, body)
  ptree = analyze(pattern).child
  dtree = DestructureRoot()
  dinfo = DestructuringInformation(dtree, Variables(constants(ptree)))
  destructure!(dinfo, ptree, dtree)
  quote
    if(!($matchtree($ptree, $ex, $(dinfo.vars))))
      throw(ArgumentError("$($(ptree)) cannot be matched with $($(clean_code(ex)))"))
    end

    $(code(dinfo, ex, body))
  end
end

function destructure!(info, pattern::PatternNode, dtree)
  dnode = DestructureNode(pattern.step, depth(dtree))
  insert!(dtree, dnode)
  destructure_children!(info, pattern, dnode)
end

function destructure!(info, pattern::PatternGate, dtree)
  if isa(pattern.check, Binding)
    binding = DestructureBind(pattern.check.name, depth(dtree))
    insert!(dtree, binding)
    push!(info.declarations, binding)
  else
    destructure!(info, pattern.child, dtree)
  end
end

function destructure!(info, pattern::PatternLeaf, dtree)
  insert!(dtree, DestructureLeaf())
end

function destructure_slurp!(info, parent, i, j, dnode)
  matchnode     = slicenode(parent, i:i)
  postmatchnode = slicenode(parent, (i+1):endof(parent.children))

  match(ex)     = match_children(matchnode, ex, 1, 1, info.vars)
  postmatch(ex) = match_children(postmatchnode, ex, 1, 1, info.vars)

  head      = parent.children[i].head
  func      = slurp_functions(head)
  consts    = constants(matchnode)
  unmatch() = unmatch_variable!(info.vars, consts)
  slurp     = DestructureSlurp(head, dnode.depth+1, func, match, postmatch, unmatch)

  insert!(dnode, slurp)
  destructure_children!(info, parent.children[i], slurp)

  set_slurp_bindings!(slurp)
end

function destructure_children!(info, pattern, dnode)
  j = 1
  for i in eachindex(pattern.children)
      is_slurp(pattern.children[i])?
        (destructure_slurp!(info, pattern, i, j, dnode); j+=1) :
        (destructure!(info, pattern.children[i], dnode))
  end
end


end