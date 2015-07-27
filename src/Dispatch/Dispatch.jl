module Dispatch
export TopMetaTable, MetaMethodTable, MetaMethod, MetaMethodError,
       getmethod, newmethod!, removemethod!, prefermethod!, prefermethod_over!,
       @macromethod, @metafunction, @metadestruct, @metadispatch

include("Structure.jl")
include("BaseImplementations.jl")
include("TableManipulation.jl")
include("TopMetaTables.jl")
include("Applications.jl")
include("MetaUtilities.jl")

using .Structure
using .TableManipulation
using .Applications
using .MetaUtilities

end