module Destructuring
using  ..Helper
export destructure, @letds, @macrods, @anonds, @funds

include("Function.jl")
include("Applications.jl")

import .Function:     destructure
import .Applications: @letds, @macrods, @anonds, @funds

end
