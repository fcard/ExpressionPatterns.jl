module Dispatch
export TopMetaTable, MetaMethodTable, MetaMethod, MetaMethodError,
       getmethod, newmethod!, removemethod!, prefermethod!, prefermethod_over!,
       @macromethod, @metafunction, @metadestruct, @metadispatch, @metamodule

include("Structure.jl")
include("BaseImplementations.jl")
include("TableManipulation.jl")
include("TopMetaTables.jl")
include("Applications.jl")
include("Reflection.jl")
include("MetaModule.jl")

using .Structure
using .TableManipulation
using .Applications
using .MetaModule

end