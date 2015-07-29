module SlurpTests
using  ExpressionPatterns.Destructuring
using  ExpressionPatterns.Analyzer
using  ExpressionPatterns.PatternStructure.SlurpTypes
using  Base.Test

# generic greedy

@test isa(analyze(:(*{x+y,z},1+1,1,*{b})).child.children[1].head, GenericGreedySlurp)

@macrods t1(*{x+y,z},1+1,1,*{b}) (x,y,z)

@test @t1(10+2, a, 30+54, b, 53+1, c, 1+1, 1, 1+1, 1) == ([10,30,53,1], [2,54,1,1], [:a,:b,:c,1])

# generic lazy

@test isa(analyze(:(?{x+y,z},1+1,1,*{b})).child.children[1].head, GenericLazySlurp)

@macrods t2(?{x+y,z},1+1,1,*{b}) (x,y,z)

@test @t2(10+2, a, 30+54, b, 53+1, c, 1+1, 1, 1+1, 1) == ([10,30,53], [2,54,1], [:a,:b,:c])

# last, simple

@test isa(analyze(:(a,b,*{c},d,e)).child.children[3].head, SimpleLastSlurp)

@macrods t3(a,b,*{c},d,e) c

@test @t3(1,2,3,4,5,6,7) == [3,4,5]

# simple, until, greedy

@test isa(analyze(:(*{a},3,*{b})).child.children[1].head, SimpleGreedySlurpUntil)

@macrods t4(*{a},3,*{b}) a

@test @t4(0,1,2,3,4,5,6) == [0,1,2]

# simple, until, lazy

@test isa(analyze(:(?{a},3,*{b})).child.children[1].head, SimpleLazySlurpUntil)

@macrods t5(?{a},3,*{b}) a

@test @t5(0,1,2,3,4,5,6) == [0,1,2]

end
