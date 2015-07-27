module Matching
using  ..Helper
export matcher, compare_trees

include("Consistency.jl")
include("Function.jl")
include("Comparison.jl")

import .Function: matcher

end
