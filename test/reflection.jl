module ReflectionTests
using  Base.Test
using  ExpressionPatterns.Dispatch
using  ExpressionPatterns.Dispatch.MetaUtilities

# pattern preference

Dispatch.set_conflict_warnings(:no)

xpy = :(x+y)
ypx = :(y+x)

@macromethod f(x+y, z)  = [x,y]
@macromethod f(z, x+y)  = [x,y]

@metafunction f(x+y, z) = [x,y]
@metafunction f(z, x+y) = [x,y]

@test @f(x+y,y+x) == [:x, :y]
@test  f(xpy,ypx) == [:x, :y]

@prefer @f(z, x+y) over @f(x+y, z)
@prefer  f(z, x+y) over  f(x+y, z)

@test @f(x+y,y+x) == [:y,:x]
@test  f(xpy,ypx) == [:y,:x]

@prefer @f(x+y, z) over @f(z, x+y)
@prefer  f(x+y, z) over  f(z, x+y)

@test @f(x+y,y+x) == [:x, :y]
@test  f(xpy,ypx) == [:x, :y]

# label preference

@macromethod g(x+y, z)[a] = [x,y]
@macromethod g(z, x+y)[b] = [x,y]

@metafunction g(x+y, z)[a] = [x,y]
@metafunction g(z, x+y)[b] = [x,y]

@test @g(x+y,y+x) == [:x, :y]
@test  g(xpy,ypx) == [:x, :y]

@prefer b over a in @g
@prefer b over a in  g

@test @g(x+y,y+x) == [:y, :x]
@test  g(xpy,ypx) == [:y, :x]

@prefer a over b in @g
@prefer a over b in  g

@test @g(x+y,y+x) == [:x, :y]
@test  g(xpy,ypx) == [:x, :y]

# method removal

@macromethod h(x+y)[plus] = [x,y]
@macromethod h(x)[any]    = [x]

@metafunction h(x+y)[plus] = [x,y]
@metafunction h(x)[any]    = [x]

@test @h(x+y)    == [:x, :y]
@test  h(:(x+y)) == [:x, :y]

@removemeta plus from @h
@removemeta plus from  h

@test @h(x+y)    == [:(x+y)]
@test  h(:(x+y)) == [:(x+y)]

@removemeta @h(x)
@removemeta  h(x)

@test_throws MetaMethodError @eval @h(x)
@test_throws MetaMethodError h(:x)

# which

MM = Dispatch.Applications.MACROMETHODS[ReflectionTests]
MF = Dispatch.Applications.METAFUNCTIONS[ReflectionTests]

@macromethod m(x)   = [x]
@macromethod m(x+y) = [x,y]

@metafunction m(x)   = [x]
@metafunction m(x+y) = [x,y]

const mmac = symbol("@m")
const mfun = :m

@test MM[mmac].methods[1] == @whichmeta @m(x+y)
@test MM[mmac].methods[2] == @whichmeta @m(x)

@test MF[mfun].methods[1] == @whichmeta m(x+y)
@test MF[mfun].methods[2] == @whichmeta m(x)

# Cross-module reflection

module A
using ..Dispatch
export @f, @g

  @macromethod f(x) (x,)
  @macromethod g(x) (x,)

end

module B
using  ExpressionPatterns.Dispatch
using  ExpressionPatterns.Dispatch.MetaUtilities
import ..A.A

  @importmeta A.@f

  @macromethod f(x+y) (x,y)
  @macromethod g(x+y) (x,y)

  @macromethod h(x+y, z) (x,y)
  @macromethod h(z, x+y) (x,y)

  @macromethod m(x+y, z)[a] (x,y)
  @macromethod m(z, x+y)[b] (x,y)

end

@test A.@f(x+y) == B.@f(x+y)
@test A.@g(x+y) != B.@g(x+y)

@test B.@h(x+y,y+x) == (:x,:y)

@prefer B.@h(z, x+y) over B.@h(x+y, z)

@test B.@h(x+y,y+x) == (:y,:x)


@test B.@m(x+y,y+x) == (:x,:y)

@prefer b over a in B.@m

@test B.@m(x+y,y+x) == (:y,:x)

@prefer a over b in B.@m

@test B.@m(x+y,y+x) == (:x,:y)

end