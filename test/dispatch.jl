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

# dispatch on slurps

@macromethod sdisp1(x)     '1'
@macromethod sdisp1(x,y)   '2'
@macromethod sdisp1(*{xs}) 'n'

@test @sdisp1(x)     == '1'
@test @sdisp1(x,y)   == '2'
@test @sdisp1(x,y,z) == 'n'

@macromethod sdisp2(*{xs}) 'n'
@macromethod sdisp2(x)     '1'

@test @sdisp2(x)   == '1'
@test @sdisp2(x,y) == 'n'

@macromethod sdisp3(f(*{as}))        (f,as...)
@macromethod sdisp3(f(*{as}; *{ks})) (f,as...,ks...)

@test @sdisp3(f(x,y))     == (:f, :x, :y)
@test @sdisp3(f(x,y;k=1)) == (:f, :x, :y, Expr(:kw, :k, 1))

# generic dispatch

@metadispatch metad_mfs() = 0
@metadispatch function metad_mfl() 0 end
@metadispatch macro metad_mm() 0 end


@metadestruct metad_fs() = 0
@metadestruct function metad_fl() 0 end

@metadestruct let (x,) = :(0,)
  @metadestruct let a = 0, b = 0
    @test 0 ==
      (@metadestruct ()->0)()    ==
      metad_fs()  == metad_fl()  ==
      metad_mfs() == metad_mfl() ==
      (@metad_mm) == x == a == b
  end
end

# metamethod overwriting

@metafunction o()[x] 1
@metafunction o()[x] 2

@test o() == 2

# errors

@test_throws MetaMethodError o(1)
@test_throws ErrorException try @eval @metafunction o(x)[x] 0; catch err throw(err.error) end

end

