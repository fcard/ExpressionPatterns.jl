module MetaModuleTests
using  Base.Test

#-----------------------------------------------------------------------------------

module A
using  ExpressionPatterns.Dispatch

@metamodule export @f,@g

@macromethod f(x) 1
@macromethod g(x) 1

end

#-----------------------------------------------------------------------------------

module B
using  ExpressionPatterns.Dispatch

@metamodule import ..A.@f

@macromethod f(x+y) 2
@macromethod g(x+y) 2

end

#-----------------------------------------------------------------------------------

module C
using  ExpressionPatterns.Dispatch

@metamodule importall ..A

@macromethod f(x-y) 3
@macromethod g(x-y) 3

end

#-----------------------------------------------------------------------------------

@test A.@f(x+y) == B.@f(x+y)
@test A.@g(x+y) != B.@g(x+y)

@test A.@f(x-y) == C.@f(x-y)
@test A.@f(x-y) == C.@f(x-y)


end