module TableManipulation
using  ...PatternStructure.Special
using  ...Destructuring.Applications
using  ...Matching.Function
using  ...Matching.Comparison
using  ...Analyzer.Function
using  ...Dispatch.Structure
import ...Destructuring.Applications: anonds
import ...Helper: clean_code
import Base.Meta: quot
export getmethod, newmethod!, removemethod!,
       prefermethod!, whichmethod, methodconflicts,
       set_conflict_warnings, callmethod

const Iterable = Union{Tuple, Vector, Set}

WARN_CONFLICTS = :interactive

#----------------------------------------------------------------------------
# Dispatch to and call method
#----------------------------------------------------------------------------

function callmethod(table, args, __source__, __module__)
  m = getmethod(table, :($(args...),))
  m(__source__, __module__, args...)
end

#----------------------------------------------------------------------------
# Format patterns to be used as arguments
#----------------------------------------------------------------------------

function formatpatterns(patterns; for_matcher=false)
  Expr(:tuple, (for_matcher ? [] : [:__source__, :__module__])..., patterns...)
end


#----------------------------------------------------------------------------
# get methods from table
#----------------------------------------------------------------------------

function getmethod(table, pattern)
  for method in table.methods
      method.matcher(pattern) && return method
  end
  throw(MetaMethodError(table.name, clean_code(pattern)))
end

#----------------------------------------------------------------------------
# Insert methods in the table
#----------------------------------------------------------------------------

function newmethod!(table, patterns, body, mod, label=unlabeled)
  mpattern = formatpatterns(patterns, for_matcher=true)
  fpattern = formatpatterns(patterns)

  match  = matcher(mpattern, mod)
  method = eval(mod, anonds(fpattern, body))
  tree   = analyze(mpattern, mod)

  metamethod = MetaMethod(label, match, method, tree)
  addmethod!(table, metamethod)
  addlabel!(table, metamethod)
  nothing
end

function addmethod!(table, method)
  methods  = table.methods
  for i in eachindex(methods)
    if method.tree == methods[i].tree
       methods[i]  =  method
       return

    elseif  method.tree ⊆ methods[i].tree
       insert!(methods, i, method)
       @goto finish

    end
  end
  push!(methods, method)
  @label finish; warn_conflicts(table, method)
end

function addlabel!(table, method)
  method.label == unlabeled && return method

  if haskey(table.labels, method.label) && !(method == table.labels[method.label])
    error("$(table.name) has a different method with label :$(method.label)")
  end
  table.labels[method.label] = method
end

#----------------------------------------------------------------------------
# Remove methods from the table
#----------------------------------------------------------------------------

function removemethod!(table, pattern, mod)
  tree    = analyze(pattern, mod)
  methods = table.methods

  for i in eachindex(methods)
    if methods[i].tree == tree
      delete!(table.labels, methods[i].label)
      splice!(methods, i)
      return
    end
  end
  warn("Couldn't remove the method $(tree) from the $(table.name)")
end

function removemethod!(table, label::Symbol, mod)
  if haskey(table.labels, label)
    method  = table.labels[label]
    methods = table.methods
    for i in eachindex(methods)
      if methods[i].tree == method.tree
        splice!(methods, i)
        delete!(table.labels, label)
        return
      end
    end
  end
  warn("Couldn't remove the method [$(label)] from the $(table.name)")
end

#----------------------------------------------------------------------------
# Manipulate preference of methods
#----------------------------------------------------------------------------

function prefermethod!(table, pattern1, pattern2, mod)
  tree1  = analyze(pattern1, mod)
  tree2  = analyze(pattern2, mod)
  prefermethod_impl!(table, tree1, tree2)
end

function prefermethod!(table, label1::Symbol, label2::Symbol, mod)
  haskey(table.labels, label1) || notfounderror(table, "label $label1")
  haskey(table.labels, label2) || notfounderror(table, "label $label2")

  tree1 = table.labels[label1].tree
  tree2 = table.labels[label2].tree
  prefermethod_impl!(table, tree1, tree2)
end

function prefermethod_impl!(table, tree1, tree2)
  if !(conflicts(tree1, tree2))
    warn("Using `prefer` with non-conflicting methods. ($(tree1) and $(tree2) in $(table.name))")
  end

  methods = table.methods
  i = findnext(met->met.tree == tree1, methods, 1)
  j = findnext(met->met.tree == tree2, methods, 1)
  if i != 0 && j != 0
    i < j && return table
    method = methods[i]
    splice!(methods, i)
    insert!(methods, j, method)
    table
  else
    sig = i == 0 ? tree1 : tree2
    notfounderror(table, "signature $(sig)")
  end
end

notfounderror(table, key) =
  throw(ArgumentError("No method with $(key) was found in $(table.name)."))

#----------------------------------------------------------------------------
# which
#----------------------------------------------------------------------------

function whichmethod(table, parameters)
  i = findnext(met->met.matcher(parameters), table.methods, 1)
  i == 0 ? nothing : table.methods[i]
end

#----------------------------------------------------------------------------
# conflicts
#----------------------------------------------------------------------------

function methodconflicts(table)
  result  = []
  methods = table.methods
  for i in eachindex(methods)
    for j in eachindex(methods)

      if i == j
        continue

      elseif methods[j].tree ⊆ methods[i].tree
        break

      elseif  conflicts(methods[i].tree, methods[j].tree) &&
             !((methods[j], methods[i]) in result)

        push!(result, (methods[i], methods[j]))
      end
    end
  end
  result
end

function methodconflicts_with(table, method)
  result  = []
  methods = table.methods
  for i in eachindex(methods)
    if method == methods[i]
      continue

    elseif methods[i].tree ⊆ method.tree
      break

    elseif conflicts(method.tree, methods[i].tree)
      push!(result, (method, methods[i]))

    end
  end
  result
end

function warn_conflicts(table, method)
  if WARN_CONFLICTS == :yes || WARN_CONFLICTS == :interactive && isinteractive()
    conflicts = methodconflicts_with(table, method)
    if !isempty(conflicts)
       warn("Method conflicts found:\n");
       print_conflicts(STDERR, conflicts)
    end
  end
end

function print_conflicts(io, conflicts)
  for c in conflicts
    print_with_color(:red,    io, "$(c[1])")
    print_with_color(:yellow, io, " | ")
    print_with_color(:red,    io, "$(c[2])")
    println(io)
    end
  println(io)
end


function set_conflict_warnings(opt::Symbol)
  if !(opt in [:yes, :interactive, :no])
    throw(ArgumentError("set_conflict_warnings must receive :yes, :no, or :interactive"))
  end
  global WARN_CONFLICTS = opt
  nothing
end


#----------------------------------------------------------------------------
# Utility functions
#----------------------------------------------------------------------------

end
