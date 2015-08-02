module Function
import ...PatternStructure.Trees: bindings
import ...Analyzer.Function: analyze
import ...Matching.Function: matchtree, newstate
import ...Matching.Environment: Variables
import ...Helper: clean_code
import Base.Meta: quot
export destructure

function destructure(pattern, ex, body)
  ptree = analyze(pattern).child
  @gensym vars
  quote
    $vars = $Variables()
    if(!($matchtree($ptree, $ex, $newstate($vars))))
      throw(ArgumentError("$($(ptree)) cannot be matched with $($(clean_code(ex)))"))
    end

    $(code(vars, ptree, body))
  end
end

code(vars, ptree, body) =
  Expr(:let, body, declarations(vars, ptree)...)

declarations(vars, ptree) =
  map(x->declare(vars, x), bindings(ptree))

declare(vars, name) =
  :($name = $(vars)[$(quot(name))])


end