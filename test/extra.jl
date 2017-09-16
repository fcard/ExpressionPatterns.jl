module ExtraTests

module UtilityTests
using Base.Test
using ExpressionPatterns
using ExpressionPatterns.Helper

cd("../src")
@test isfile(ExpressionPatterns.path("Analyzer"))
cd("../test")

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

module TreeComparison
using Base.Test
using ExpressionPatterns.Analyzer
using ExpressionPatterns.Matching.Comparison

totree(x) = analyze(x, TreeComparison)

@test totree(:(a,*{x}))   ⊆ totree(:(*{x},))
@test totree(:(*{x},))    ⊇ totree(:(a,*{x}))
@test totree(:(*{x},1))   ⊇ totree(:(*{x},2,1))
@test totree(:(*{x},2,1)) ⊆ totree(:(*{x},1))

end

end
