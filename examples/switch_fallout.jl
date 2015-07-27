# switch statement (with fallout)

macro switch(value, block)
  @gensym value_sym
  clauses, statements = switch(value_sym, block)
  :(for i in 1:1
      let $(esc(value_sym)) = $value
          $(clauses)
          $(esc(statements))
      end
    end)
end

@metafunction switch(value, begin :L{:case}(x); ?{xs}; :L{:case}(y); *{ys} end) begin
  @gensym label
  nextclauses, nextstatements = switch(value, quote :case($y); $(ys...) end)
  clauses    = switch_clause(value, x, label, nextclauses)
  statements = switch_statements(xs, label, nextstatements)

  clauses, statements
end

@metafunction switch(value, begin :L{:case}(x); *{xs} end) begin
  @gensym label
  clauses    = switch_clause(value, x, label)
  statements = switch_statements(xs, label)

  clauses, statements
end

switch_clause(value, x, label, nextclauses=nothing) = quote
  if $value == $x
    @goto $label
  else
    $nextclauses
  end
end

switch_statements(statements, label, nextstatements=nothing) = quote
  @label $label
  $(statements...);
  $(nextstatements)
end

# usage

r = 0
a = 2

@switch a begin
  :case(1);
    r = 1
    break

  :case(2);
    r = 2

  :case(3);
    r = 3

end

import Base.Test.@test

if a in [1,2]
  @test a != 1 || r == 1
  @test a != 2 || r == 3
end
