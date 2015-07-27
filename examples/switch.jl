# switch statement


macro switch(value, block)
  @gensym value_sym

  :(for i in 1:1
  	  let $(esc(value_sym)) = $value
          $(esc(switch(value_sym, block)))
      end
    end)
end

@metafunction switch(value, begin :L{:case}(x); ?{xs}; :L{:case}(y); *{ys} end) begin
  next = switch(value, quote :case($y); $(ys...) end)
  switch_clause(value, x, xs, next)
end

@metafunction switch(value, begin :L{:case}(x); *{xs} end) begin
  switch_clause(value, x, xs)
end

switch_clause(value, x, xs, next=nothing) = quote
  if $value == $x
    $(xs...)
  else
    $next
  end
end


r = 0
a = 2

@switch a begin
  :case(1);
    r = 1

  :case(2);
    r = 2

end

if a in [1,2]
  @test a != 1 || r == 1
  @test a != 2 || r == 2
end