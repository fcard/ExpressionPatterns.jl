module BaseImplementation
using  ...Dispatch.Structure
import Base: showerror, ==, call, show, display


call(met::MetaMethod, exprs...) = met.method(exprs...)

function show(io::IO, met::MetaMethod)
  args = map(met.tree.child.children) do tree
    s = sprint(show, tree)
    s = replace(s, r"pattern{.*?}<", "", 1)[1:end-1]
  end
  consts  = match(r"pattern{consts: (.*?)}", sprint(show, met.tree))
  consts  = isa(consts, Void)? "" : consts[1]
  label   = met.label == unlabeled? "[---]" : "[$(met.label)]"

  (print(io, label, "{$consts}<"))
  [print(io, arg,   " ") for arg in args[1:end-1]]
  (print(io, args[end], ">"))
end

function show(io::IO, table::MetaMethodTable)
  print(io, table.name)
end

function display(io::IO, table::MetaMethodTable)
  println(io, table.name, " with $(length(table.methods)) methods:")
  for methods in table.methods
    println(io, " ", method)
  end
end

showerror(io::IO, err::MetaMethodError) =
  print(io, "$(err.name) has no method that matches $(err.expr).")

end