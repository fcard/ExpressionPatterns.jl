module Special
using  ...PatternStructure.Trees
using  ...PatternStructure.Checks
using  ...PatternStructure.SlurpTypes
import Base.Meta.isexpr
export special_heads, special_shortcuts, is_slurp, is_special,
       slurptype, patterntype, special_name, is_special_expr,
       is_binding_name

const special_heads =
  [:literal, :autobinding, :binding, :type, :consistent, :predicate, :equals, :iterable, :raw]

const special_shortcuts =
  Dict(:(:A) => :(:autobinding),
       :(:L) => :(:literal),
       :(:B) => :(:binding),
       :(:T) => :(:type),
       :(:C) => :(:consistent),
       :(:P) => :(:predicate),
       :(:I) => :(:iterable),
       :(:E) => :(:equals),
       :(:EQ)=> :(:equals),
       :(:R) => :(:raw)
       )

is_slurp(node::PatternNode) = isa(node.head, SlurpHead)
is_slurp(x) = false

is_special(node::PatternNode) = node.head in special_heads || is_slurp(node)

slurptype(node::PatternNode) =
  isa(node.head, LazySlurp)   ? :? :
  isa(node.head, GreedySlurp) ? :* :
  throw(ArgumentError(
    "Couldn't determine the slurp type of the pattern node $(node.head)"))

patterntype(node::PatternNode) =
  is_slurp(node) ? slurptype(node) : node.head

extract_name(x::QuoteNode) = x.value
extract_name(x) = x

special_name(x)       = extract_name(get(special_shortcuts, x, x))
special_name(x::Expr) = special_name(QuoteNode(x.args[1]))

function is_binding_name(x::Symbol)
  firstchar = string(x)[1]

  isalpha(firstchar) || firstchar in ['#', '@', '_']
end
is_binding_name(x) = false

function is_special_expr(ex::Expr)
  if ex.head == :curly && ex.args[1] == :?
    warn("?{...} is deprecated, use :?{...}")
    ex.args[1] = :(:?)
  end

  ex.head == :curly &&
    (isa(ex.args[1], QuoteNode) ||
    (isexpr(ex.args[1], :quote) ||
    (ex.args[1] in [:(:?), :(*)])))
end


end
