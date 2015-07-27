module Structure
using  ...PatternStructure.Trees
export MetaMethod, MetaMethodTable, MetaMethodError, unlabeled

immutable MetaMethod
  label   :: Symbol
  matcher :: Function
  method  :: Function
  tree    :: PatternRoot
end

immutable MetaMethodTable
  name    :: String
  labels  :: Dict{Symbol, MetaMethod}
  methods :: Vector{MetaMethod}

  MetaMethodTable(name) =
    new(name, Dict{Symbol, MetaMethod}(), MetaMethod[])
end

immutable MetaMethodError <: Exception
  name :: String
  expr :: Any
end


const unlabeled = gensym("unlabeled")

end