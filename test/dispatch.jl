module DispatchTests
using  ExpressionPatterns.Dispatch
using  Base.Test
# works?

@macromethod  w1(x) x
@metafunction w1(x) x
@macromethod  w2(x) = x
@metafunction w2(x) = x

@test @w1(1) == @w2(1) == w1(1) == w2(1)

# parameter dispatch

@macromethod param(x)   1
@macromethod param(x,y) 2

@test @param(a)   == 1
@test @param(a,b) == 2

# expression dispatch

@macromethod disp( x+y ) 1
@macromethod disp( x-y ) 2
@macromethod disp((x,y)) 3
@macromethod disp([x+y]) 4

@test @disp( x+y ) == 1
@test @disp( x-y ) == 2
@test @disp((x,y)) == 3
@test @disp([x+y]) == 4

# inteligent dispatch: matches the most specific, regardless of definition order

@macromethod intdisp1(x)   1
@macromethod intdisp1(x+y) 2

@macromethod intdisp2(x+y) 2
@macromethod intdisp2(x)   1

@test @intdisp1(x)   == 1
@test @intdisp1(x+y) == 2

@test @intdisp2(x)   == 1
@test @intdisp2(x+y) == 2

@metafunction intdisp3(:T{x, Number})  Number
@metafunction intdisp3(:T{x, Integer}) Integer

@metafunction intdisp4(:T{x, Integer}) Integer
@metafunction intdisp4(:T{x, Number})  Number

@test intdisp3(10.0) == Number
@test intdisp3(1000) == Integer

@test intdisp4(10.0) == Number
@test intdisp4(1000) == Integer

end