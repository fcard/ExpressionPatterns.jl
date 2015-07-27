module Analyzer
using  ..Helper
export analyze

include("SlurpOptimizations.jl")
include("Function.jl")

import .Function: analyze

end
