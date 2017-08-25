module SlurpTests
using  ExpressionPatterns.Destructuring
using  ExpressionPatterns.Analyzer
using  ExpressionPatterns.PatternStructure.SlurpTypes
using  Base.Test

macro test_slurp(body)
  let pattern, index, typ, value, test
    for (left, right) in (pair_vals(x) for x in body.args if is_pair_ex(x))
      left == :pattern ? (pattern = right) :
      left == :index   ? (index   = right) :
      left == :type    ? (typ     = right) :
      left == :value   ? (value   = right) :
      left == :test    ? (test    = right) : nothing
    end
    esc(quote
      @test isa($analyze($(QuoteNode(pattern)), @__MODULE__).child.children[$index].head, $typ)
      @letds $pattern = $value begin
        @test $test
      end
    end)
  end
end
is_pair_ex(x) = false
is_pair_ex(ex::Expr) = ex.head in [:(=>), :call]

pair_vals(ex) = (ex.args[ex.head == :(=>) ? 1 : 2].args[1], ex.args[end])


# generic greedy

@test_slurp begin
  :pattern => (*{x+y,z},1+1,1,*{b})
  :index   => 1
  :type    => GenericGreedySlurp
  :value   => :(10+2, a, 30+54, b, 53+1, c, 1+1, 1, 1+1, 1)
  :test    => (x,y,z) == ([10, 30, 53, 1], [2, 54, 1, 1], [:a, :b, :c, 1])
end

# generic lazy

@test_slurp begin
  :pattern => (:?{x+y,z},1+1,1,*{b})
  :index   => 1
  :type    => GenericLazySlurp
  :value   => :(10+2, a, 30+54, b, 53+1, c, 1+1, 1, 1+1, 1)
  :test    => (x,y,z) == ([10,30,53], [2,54,1], [:a,:b,:c])
end

# last, simple

@test_slurp begin
  :pattern => (a,b,*{c},d,e)
  :index   => 3
  :type    => SimpleLastSlurp
  :value   => :(1,2,3,4,5,6,7)
  :test    => c == [3,4,5]
end

# simple, until, greedy

@test_slurp begin
  :pattern => (*{a},3,*{b})
  :index   => 1
  :type    => SimpleGreedySlurpUntil
  :value   => :(0,1,2,3,4,5,6)
  :test    => a == [0,1,2]
end

# simple, until, lazy

@test_slurp begin
  :pattern => (:?{a},3,*{b})
  :index   => 1
  :type    => SimpleLazySlurpUntil
  :value   => :(0,1,2,3,4,5,6)
  :test    => a == [0,1,2]
end

end
