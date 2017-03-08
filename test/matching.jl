module MatchingTests
using  ExpressionPatterns.Matching
using  ExpressionPatterns.Helper
using  Base.Test
import Base.Meta.quot

matchval(exval) = :(@test match($(exval[1])) == $(exval[2]))

macro testmatch(pattern, block)

  arg_statements = (x->esc.(x.args[2:end])).(linesof(block))
  res_statements = matchval.(arg_statements)

  :(let match = $matcher($(esc(pattern)))
      $(res_statements...)
    end)
end


# anything

@testmatch (:x) begin
   1000   => true
  :(x,y)  => true
  :(x+10) => true
end

# tuple

@testmatch :(x,y,z) begin
  :(a,b,c) => true
  :(1,2,3) => true
  :[a,b,c] => false
  :(1,2)   => false
end

# vector / literal

@testmatch :[1,a] begin
  :[1,2]        => true
  :[1,:(a,b,c)] => true
  :[1,b,c]      => false
  :[a,a]        => false
  :[[1],a]      => false
  :(1,2)        => false
end

# call

@testmatch :(f(a,b)) begin
  :(1+2)                  => true
  :(reduce(*, [1,2,3,4])) => true
  :(g[1,2])               => false
  :(t{a,b})               => false
end

# ref

@testmatch :((:T{Symbol})[:T{Integer}]) begin
  :(A[1])      => true
  :(arr[1000]) => true
  :(A[1,2])    => false
  :(1[1])      => false
  :(A[a])      => false
end

# curly

@testmatch (:(T{*{a}})) begin
  :(Vector{Integer}) => true
  :(A{1,2,3,4})      => true
  :(T{})             => true
end

# block

@testmatch (quote *{:T{:P{islower}, AbstractString}} end) begin
  (quote "abc"; "onetwothree"; "solami" end) => true
  (quote "abc";     "123";     "solami" end) => false
  (quote "abc"; "onetwothree"; "solami" end) => true
  (quote "aBc"; "onetwothree"; "solami" end) => false
  (quote "abc";      123;      "solami" end) => false
end

# forloop / nested slurps

@testmatch :(for i in [*{[*{1,2}]}]; *{body} end) begin
  :(for x in [[1,2],[],[1,2,1,2]]; print(x) end) => true
  :(for x in [[1,2],[],[1,2,1]];   print(x) end) => false
  :(for x in [[1,2],[3],[1,2,1]];  print(x) end) => false
end

# while loop / lazy slurps

@testmatch :(while x < t; ?{p(?{args})}; x+=1 end) begin

  :(while i <   10; println(io, i);             i+=1 end) => true
  :(while k < t-10; splice!(A,2,k); push!(B,k); k+=1 end) => true
  :(while x < g(x); println(x);     push!(B,x); x+=1 end) => true
  :(while x < g(x); println(i);     push!(B,x); x+=1 end) => true
  :(while x < g(x); println(x,y);   push!(B,x); i+=1 end) => false
  :(while x > g(x); println(x);     push!(B,x); x+=2 end) => false

end

# macrocall / quote

@testmatch :(@m :x y) begin
  :(@transport :car   (john, peter))    => true
  :(@transport plane  (maria, isabela)) => false
end

# binding

@testmatch (:(:B{+}(1+2))) begin
  :(f(1+2)) => true
  :(f(1-2)) => false
end

# literal

@testmatch :(:L{x+y}) begin
  :(x+y) => true
  :(1+2) => false
end

# autobinding

@testmatch :(:L{:A{x+y}}) begin
  :(1+2) => true
  :(x+y) => true
  :(x-y) => false
end

# consistency

@testmatch :(x, x) begin
  :(1,1) => true
  :(1,2) => false
end

# equality

@testmatch :(:EQ{x, 10}) begin
  10 => true
  11 => false
end

# type check

@testmatch :(:T{x, Symbol}) begin
  :x => true
  10 => false
end

# predicate check

@testmatch :(:P{x, iseven}) begin
  2 => true
  1 => false
end

# iterable

@testmatch :(:I{x,y,z}) begin
  (1,2,3) => true
  [4,5,6] => true
 :(7,8,9) => false
 :[a,b,c] => false
end

# raw

@testmatch :(:R{:export, x, y, z}) begin
  :(export a,b,c) => true
  :(import a.b.c) => false
end

end
