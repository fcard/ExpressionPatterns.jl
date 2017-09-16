module ReflectionTests
using  Base.Test
using  ExpressionPatterns
using  ExpressionPatterns.Dispatch
using  ExpressionPatterns.Dispatch.Reflection

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

@remove plus from @h
@remove plus from  h

@test @h(x+y)    == [:(x+y)]
@test  h(:(x+y)) == [:(x+y)]

@remove @h(x)
@remove  h(x)

@test_throws MetaMethodError try @eval @h(x); catch err throw(err isa LoadError ? err.error : err) end
@test_throws MetaMethodError h(:x)

# which

MM = Dispatch.Applications.MACROMETHODS[ReflectionTests]
MF = Dispatch.Applications.METAFUNCTIONS[ReflectionTests]

@macromethod m(x)   = [x]
@macromethod m(x+y) = [x,y]

@metafunction m(x)   = [x]
@metafunction m(x+y) = [x,y]

const mmac = Symbol("@m")
const mfun = :m

@test MM[mmac].methods[1] == @whichmeta @m(x+y)
@test MM[mmac].methods[2] == @whichmeta @m(x)

@test MF[mfun].methods[1] == @whichmeta m(x+y)
@test MF[mfun].methods[2] == @whichmeta m(x)

# conflicts

@macromethod n(x,x+y)[a] ()
@macromethod n(x+y,x)[b] ()

let stdout = STDOUT
  conflicts_io, = redirect_stdout()
  @metaconflicts @n
  print_with_color(:red,    "[a]<x x + y>")
  print_with_color(:yellow, " | ")
  print_with_color(:red,    "[b]<x + y x>")
  println()

  metaconflicts_result = readline(conflicts_io)
  readline(conflicts_io)
  expected = readline(conflicts_io)

  redirect_stdout(stdout)
  @test metaconflicts_result == expected
end


# Cross-module reflection

module A
using ..Dispatch
export @f, @g

  @macromethod f(x) (x,)
  @macromethod g(x) (x,)

end

module B
using  ExpressionPatterns.Dispatch
using  ExpressionPatterns.Dispatch.Reflection

  @metamodule import ..A.@f

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

# Errors and warnings

macro test_warning(ex, expected_warning::String)
  @gensym had_color
  quote
    let
      token  = gensym()
      stderr = STDERR
      nerr,  = redirect_stderr()

      $(esc(had_color)) = Base.have_color
      eval($Base, :(have_color = false))
      try
        $(esc(ex))
        println(STDERR)
        println(STDERR, "$token")
        warning = readline(nerr)
        line = (eof(nerr) ? "" : readline(nerr))
        while line != "$token"
          if line != ""
            warning = "$warning\n$line"
          end
          line = readline(nerr)
        end
        @test warning == $expected_warning
      finally
        redirect_stderr(stderr)
        eval($Base, :(have_color = $$had_color))
      end
    end
  end
end

@test_throws ArgumentError ExpressionPatterns.Dispatch.TableManipulation.set_conflict_warnings(:bleh)

ExpressionPatterns.Dispatch.TableManipulation.set_conflict_warnings(:yes)

@macromethod m()[a] ()
@test_warning (@prefer a over a in @m) "WARNING: Using `prefer` with non-conflicting methods. (pattern`()` and pattern`()` in macromethod m)"
@test_warning (@remove b from @m)      "WARNING: Couldn't remove the method [b] from the macromethod m"

ExpressionPatterns.Dispatch.TableManipulation.set_conflict_warnings(:no)

end
