module BaseImplementation
using  ...Dispatch.Structure
import Base: showerror, ==, show, display


(met::MetaMethod)(exprs...) = met.method(exprs...)

function show(io::IO, met::MetaMethod)
  args = map(met.tree.child.children) do tree
    s = sprint(show, tree)
    s = replace(s, r"pattern`", "", 1)[1:end-1]
  end
  label = met.label == unlabeled ? "[---]" : "[$(met.label)]"

  print(io, label, "<", join(args, " "), ">")
end

function show(io::IO, table::MetaMethodTable)
  if get(io, :compact, false)
    print(io, table.name)
  else
    len = length(table.methods)
    println(io, table.name, " with $len method$(len==1 ? "" : "s"):")
    for method in table.methods
      println(io, " ", method)
    end
  end
end

showerror(io::IO, err::MetaMethodError) =
  print(io, "$(err.name) has no method that matches $(err.expr).")

end
