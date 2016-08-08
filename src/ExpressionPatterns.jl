__precompile__()

module ExpressionPatterns
export @metadispatch, @metadestruct

path(name) = joinpath(name, "$name.jl")

include(path("Helper"))
include(path("PatternStructure"))
include(path("Analyzer"))
include(path("Matching"))
include(path("Destructuring"))
include(path("Dispatch"))
include(path("Docs"))

import .Dispatch: @metadestruct, @metadispatch
end
