module DestructuringTests
using  ExpressionPatterns.Destructuring
using  ExpressionPatterns.Dispatch
using  Base.Test

macro anyvec(x) anyvec(x) end

@metafunction anyvec(x) = x
@metafunction anyvec([*{elts}]) = :(Any[$(map(anyvec, elts)...)])


## letds

# No destructuring.
@letds x = 10 y = 20 @test (x,y) == (10,20)

# Basic destructuring.
@letds (x,y) = :(x,y) @test (x,y) == (:x,:y)

# Destructuring with nested expressions.
@letds f((a+b),c{d}) = :(func(10+20,A{T})) begin
  @test (f,a,b,c,d) == (:func,10,20,:A,:T)
end

# Destructuring with slurps.
@letds (for x in [*{elts}]; *{body}  end) =
      :(for i in [1,2,3,4]; print(i) end) begin

  @test (x,elts,body) == (:i, Any[1,2,3,4], Any[:(print(i))])
end

# Destructuring with alterning slurps.
@letds [*{a,b}] = :[1,2,3,4] @test (a,b) == ([1,3],[2,4])

# Destructuring with multiple slurps
@letds [*{before3}, 3, *{after3}] = :[1,2,3,4,5] begin
  @test (before3,after3) == ([1,2],[4,5])
end

# Destructuring with nested slurps.
@letds (begin *{f(*{elts})}  end) =
      :(begin f(1,2); g(2,3,4) end) begin

  @test f    == [:f, :g]
  @test elts == @anyvec [[1,2],[2,3,4]]
end

# Triple nested slurps! this is fun!
@letds (begin *{[*{f(*{(*{elts},)})}]} end) =
      :(begin [f((x,y),(a,b)), g((1,2),(4,5))]
      	      [h((1,2,3,4))] end) begin

  @test f    == @anyvec [[:f, :g], [:h]]
  @test elts == @anyvec [[[[:x,:y],[:a,:b]],[[1,2],[4,5]]],[[[1,2,3,4]]]]
end

## macrods

@macrods nodestruct(x,y,z) (x,y,z)
@test   @nodestruct(a,10+20,f(x,y)) == (:a,:(10+20), :(f(x,y)))


@macrods basicdestruct(x+y) (x,y)
@test   @basicdestruct(1+2) == (1,2)


@macrods nestedexpr(f(x::T1, y::T2) = body) (f,x,y,T1,T2,body)
@test   @nestedexpr(add(a::Int, b::Int) = a+b) == (:add, :a,:b,:Int,:Int,:(a+b))


@macrods withslurp(for x in  coll;     *{body}   end)    :(map($coll)   do $x; $(body...) end)
@test   @withslurp(for i in [1,2,3]; i*=2; i+10; end) ==  [12, 14, 16]


#alternating slurps
@macrods switch(x, begin *{case(c),expr} end) (x,c,expr)
ex=
@switch i begin
  case(1); print(1);
  case(2); println(2);
end
@test ex == (:i, [1,2], [:(print(1)), :(println(2))])

@macrods nestedslurp([*{(*{tuple_elts},), [*{vector_elts}]}]) (tuple_elts, vector_elts)
@test   @nestedslurp([(1,2,3), [2,3,4], (3,2,5), [7,4,3]]) ==
        (Any[[1,2,3],[3,2,5]], Any[[2,3,4], [7,4,3]])


## anonds | funds

@test @anonds((x,y) -> x+y)(1,2) == 3

@test @anonds(f(x,y) -> :($f($x)($y)))(:(g(1,2))) == :(g(1)(2))

@test @anonds(*{a,b,c} -> (a,b,c))(1,2,3,4,5,6) == ([1,4],[2,5],[3,6])

@funds olddict((K=>V)(*{keys=>values},)) = :(Dict{$K,$V}($([:($key=>$value) for (key,value) in zip(keys,values)]...)))
@test  olddict(:((Symbol=>Int)(:a=>1, :b=>2, :c=>3))) == :(Dict{Symbol,Int}(:a=>1, :b=>2, :c=>3))

end