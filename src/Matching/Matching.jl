module Matching
using  ..Helper
export matcher, compare_trees

include("Environment.jl")
include("Function.jl")
include("Comparison.jl")

import .Function: matcher

end
