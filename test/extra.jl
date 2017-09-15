module ExtraTests

module UtilityTests
using Base.Test
using ExpressionPatterns
using ExpressionPatterns.Helper

@test ExpressionPatterns.path("x") == "x/x.jl"
@test clean_code(quote x end).args == [:x]


end

module PrintingTests
using Base.Test
using ExpressionPatterns
using ExpressionPatterns.Dispatch
using ExpressionPatterns.Dispatch.Reflection

@metafunction f(x,y) = ()
@metafunction g()[g] = ()
@metafunction h()    = ()
@metafunction h(x)   = ()

totree(ex) = ExpressionPatterns.Analyzer.analyze(ex, PrintingTests)
showcpt(io, ex) = show(IOContext(io, :compact=>true), ex)

@test sprint(show, totree(:(10)))     == "pattern`10`"
@test sprint(show, totree(:(x+y)))    == "pattern`x + y`"
@test sprint(show, totree(:(*{x})))   == "pattern`(:*){x}`"
@test sprint(show, totree(:(:?{x})))  == "pattern`(:?){x}`"

@test sprint(show, totree(:(:T{x,Int64})))   == "pattern`(:type){x, Int64}`"
@test sprint(show, totree(:(:L{x})))         == "pattern`(:equals){x}`"
@test sprint(show, totree(:(:B{+})))         == "pattern`(:binding){+}`"
@test sprint(show, totree(:(:P{x, iseven}))) == "pattern`(:predicate){x, iseven}`"

@test sprint(show, (@metamethods f)[1])   == "[---]<x y>"
@test sprint(show, (@metamethods g)[1])   == "[g]<>"

import ExpressionPatterns.Dispatch.Reflection.metafuntable
@test sprint(showcpt, metafuntable(:f, PrintingTests)) == "metafunction f"
@test sprint(show,    metafuntable(:f, PrintingTests)) == "metafunction f with 1 method:\n [---]<x y>\n"
@test sprint(show,    metafuntable(:h, PrintingTests)) == "metafunction h with 2 methods:\n [---]<>\n [---]<x>\n"

end

module MakeDocsTest

cd("../src/Docs")
include("../src/Docs/makedocs.jl")
cd("../../test")

end

end
