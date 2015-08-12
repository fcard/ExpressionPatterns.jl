

@macromethod d(x -> x) esc(:($x -> 1))
@macromethod d(x -> y) esc(:($x -> 0))

@macromethod d(x -> x^(:T{n, Number})) esc(:($x -> $n*($x^($n-1))))

@macromethod d(x -> a+b) esc(:($x -> @d($x -> $a)($x) + @d($x -> $b)($x)))
@macromethod d(x -> a-b) esc(:($x -> @d($x -> $a)($x) - @d($x -> $b)))

@macromethod d(x -> a*b) esc(:($x -> $a * @d($x -> $b)($x) +
                                     $b * @d($x -> $a)($x)))

@macromethod d(x -> a/b) esc(:($x -> ($b * @d($x -> $a)($x) -
                                      $a * @d($x -> $b)($x))/
                                     ($b^2)))



@d(x -> 4x)(1) == 4

@d(x -> 10x^2 + 5x)(10) == (x-> 20x + 5)(10)

@d(x -> 20x^2/(x+2))(12) == (x-> (40x*(x+2) - (20x^2))/((x+2)^2))(12)
