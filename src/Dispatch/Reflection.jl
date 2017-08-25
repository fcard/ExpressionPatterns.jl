module Reflection
using  ...Dispatch.Applications
using  ...Dispatch.TableManipulation
using  ...Dispatch.TopMetaTables
import ...Dispatch.Applications: MACROMETHODS, METAFUNCTIONS
import  ...Dispatch.TableManipulation: print_conflicts
import Base.Meta: quot
export @prefer, @whichmeta, @remove, @importmeta, @metamethods, @metaconflicts

name(macroname) = Symbol(string(macroname)[1:end])

macrotable(macroname,M) =
  get_metatable(MACROMETHODS, M, name(macroname))

metafuntable(funname,M) =
  get_metatable(METAFUNCTIONS, M, funname)

gettable(typ, m) =
  typ == :macro ?
    M -> macrotable(m, M) :
    M -> metafuntable(m, M)

preparg(x::Symbol) = quot(x)
preparg(x::Vector) = :(Expr(:tuple, $x...))

prefercode(m, arg1, arg2, typ, M) =
  :($(prefermethod!)($(gettable(typ, m))($M), $(preparg(arg1)), $(preparg(arg2)), $M))

whichcode(m, patterns, typ, M) =
  :($(whichmethod)($(gettable(typ, m))($M), Expr(:tuple, $(patterns)...)))

removecode(m, arg, typ, M) =
  :($(removemethod!)($(gettable(typ, m))($M), $(preparg(arg)), $M))

methodscode(m, typ, M) =
  :($(gettable(typ, m))($M).methods)

conflictscode(m, typ, M) =
  :($(print_conflicts)(STDOUT, $(methodconflicts)($(gettable(typ, m))($M))))

#----------------------------------------------------------------------------
# which
#----------------------------------------------------------------------------

@macromethod whichmeta(   m(*{patterns})) = whichcode(m, patterns, :fun, __module__)
@macromethod whichmeta( M.m(*{patterns})) = whichcode(m, patterns, :fun, M)
@macromethod whichmeta(  @m(*{patterns})) = whichcode(m, patterns, :macro, __module__)
@macromethod whichmeta(M.@m(*{patterns})) = whichcode(m, patterns, :macro, M)


#----------------------------------------------------------------------------
# preference
#----------------------------------------------------------------------------

@macromethod prefer(   m(*{p1}), :L{over},    m(*{p2})) = esc(prefercode(m, p1, p2, :fun, __module__))
@macromethod prefer( M.m(*{p1}), :L{over},  M.m(*{p2})) = esc(prefercode(m, p1, p2, :fun, M))
@macromethod prefer(  @m(*{p1}), :L{over},   @m(*{p2})) = esc(prefercode(m, p1, p2, :macro, __module__))
@macromethod prefer(M.@m(*{p1}), :L{over}, M.@m(*{p2})) = esc(prefercode(m, p1, p2, :macro, M))

@macromethod prefer(label1, :L{over}, label2 in    m) = esc(prefercode(m ,label1, label2, :fun, __module__))
@macromethod prefer(label1, :L{over}, label2 in  M.m) = esc(prefercode(m ,label1, label2, :fun, M))
@macromethod prefer(label1, :L{over}, label2 in   @m) = esc(prefercode(m ,label1, label2, :macro, __module__))
@macromethod prefer(label1, :L{over}, label2 in M.@m) = esc(prefercode(m ,label1, label2, :macro, M))

#----------------------------------------------------------------------------
# remove
#----------------------------------------------------------------------------

@macromethod remove(   m(*{patterns})) = esc(removecode(m, patterns, :fun, __module__))
@macromethod remove( M.m(*{patterns})) = esc(removecode(m, patterns, :fun, M))
@macromethod remove(  @m(*{patterns})) = esc(removecode(m, patterns, :macro, __module__))
@macromethod remove(M.@m(*{patterns})) = esc(removecode(m, patterns, :macro, M))

@macromethod remove(label, :L{from},    m) = esc(removecode(m, label, :fun, __module__))
@macromethod remove(label, :L{from},  M.m) = esc(removecode(m, label, :fun, M))
@macromethod remove(label, :L{from},   @m) = esc(removecode(m, label, :macro, __module__))
@macromethod remove(label, :L{from}, M.@m) = esc(removecode(m, label, :macro, M))


#----------------------------------------------------------------------------
# metamethods
#----------------------------------------------------------------------------

@macromethod metamethods(   m) = esc(methodscode(m, :fun, __module__))
@macromethod metamethods( M.m) = esc(methodscode(m, :fun, M))
@macromethod metamethods(  @m) = esc(methodscode(m, :macro, __module__))
@macromethod metamethods(M.@m) = esc(methodscode(m, :macro, M))


#----------------------------------------------------------------------------
# metaconflicts
#----------------------------------------------------------------------------

@macromethod metaconflicts(   m) = esc(conflictscode(m, :fun, __module__))
@macromethod metaconflicts( M.m) = esc(conflictscode(m, :fun, M))
@macromethod metaconflicts(  @m) = esc(conflictscode(m, :macro, __module__))
@macromethod metaconflicts(M.@m) = esc(conflictscode(m, :macro, M))


end
