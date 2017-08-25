module Applications
using  ...Dispatch.Structure
using  ...Dispatch.TableManipulation
using  ...Dispatch.TopMetaTables
using  ...Destructuring.Applications
using  ...ExpressionPatterns
import Base.Meta: quot
export @macromethod, @metafunction, @metadestruct, @metadispatch

#----------------------------------------------------------------------------
# Macromethods
#----------------------------------------------------------------------------

const DI = ExpressionPatterns.Dispatch.Applications
const MACROMETHODS = TopMetaTable()

@macrods macromet(name(*{patterns})[label], body) begin
  esc(macromet(name, patterns, label, body, __module__))
end

function macromet(name, patterns, label, body, mod)
  init_metatable!(MACROMETHODS, mod, Symbol("@$name"), "macromethod $name")
  macrotable = get_metatable(MACROMETHODS, mod, Symbol("@$name"))
  undefined  = isempty(macrotable.methods)

  code =
    quote
      $newmethod!($macrotable, $patterns, $(quot(body)), $mod, $(quot(label)))
    end

  if undefined
    push!(code.args,
      :(macro $name(args...)
          $callmethod($macrotable, args, __source__, __module__)
        end))
  end
  return code
end

# normal, to be used as:
# @macromethod name(patterns...)[label] begin end


@macromet macromethod(name(*{patterns})[label], body)[with_label] begin
  esc(macromet(name, patterns, label, body, __module__))
end

@macromet macromethod(name(*{patterns}), body)[no_label] begin
  esc(macromet(name, patterns, unlabeled, body, __module__))
end

# assignment, to be used as @macromethod name(patterns...)[label] = expr

@macromet macromethod(name(*{patterns})[label] = body)[eq_with_label] begin
  esc(macromet(name, patterns, label, body, __module__))
end

@macromet macromethod(name(*{patterns}) = body)[eq_no_label] begin
  esc(macromet(name, patterns, unlabeled, body, __module__))
end

# the [label] is optional in all definitions

#----------------------------------------------------------------------------
# Metafunctions
#----------------------------------------------------------------------------

const METAFUNCTIONS = TopMetaTable()

# normal

@macromethod metafunction(name(*{patterns})[label], body)[with_label] =
  esc(metafunction(name, patterns, label, body, __module__))

@macromethod metafunction(name(*{patterns}), body)[no_label] =
  esc(metafunction(name, patterns, unlabeled, body, __module__))

# assignment

@macromethod metafunction(name(*{patterns})[label] = body)[eq_with_label] =
  esc(metafunction(name, patterns, label, body, __module__))

@macromethod metafunction(name(*{patterns}) = body)[eq_no_label] =
  esc(metafunction(name, patterns, unlabeled, body, __module__))


function metafunction(name, patterns, label, body, mod)
  init_metatable!(METAFUNCTIONS, mod, name, "metafunction $name")
  metatable = get_metatable(METAFUNCTIONS, mod, name)
  undefined = isempty(metatable.methods)

  code =
    quote
      $newmethod!($metatable, $patterns, $(quot(body)), $mod, $(quot(label)))
    end

  if undefined
    push!(code.args,
      :(function $name(args...; __module__=nothing, __source__=nothing)
          $callmethod($metatable, args, __source__, __module__)
        end))
  end
  return code
end

#----------------------------------------------------------------------------
# Metadestruct
#----------------------------------------------------------------------------
const DE = ExpressionPatterns.Destructuring.Applications

@macromethod metadestruct(let *{bindings}; *{body} end)[letds] =
  esc(:($DE.@letds $(bindings...) begin $(body...) end))

@macromethod metadestruct(macro name(*{patterns}) *{body} end)[macrods] =
  esc(:($DE.@macrods $name($(patterns...)) begin $(body...) end))

@macromethod metadestruct(patterns -> body)[anonds] =
  esc(:($DE.@anonds $patterns -> $body))

@macromethod metadestruct(name(*{patterns}) = body)[funds_short] =
  esc(:($DE.@funds $name($(patterns...)) = $body))

@macromethod metadestruct(function name(*{patterns}); *{body} end)[funds_long] =
  esc(:($DE.@funds $name($(patterns...)) = begin $(body...) end))

#----------------------------------------------------------------------------
# Metadispatch
#----------------------------------------------------------------------------
#const DI = ExpressionPatterns.Dispatch.Applications

@macromethod metadispatch(macro name(*{patterns}) *{body} end)[macromethod] =
  esc(:($DI.@macromethod $name($(patterns...)) begin $(body...) end))

@macromethod metadispatch(name(*{patterns}) = body)[metafun_short] =
  esc(:($DI.@metafunction $name($(patterns...)) $body))

@macromethod metadispatch(function name(*{patterns}); *{body} end)[metafun_long] =
  esc(:($DI.@metafunction $name($(patterns...)) begin $(body...) end))

end
