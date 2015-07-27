module Consistency
export Variables, match_variable!, unmatch_variable!

type Variables
  names  :: Set{Symbol}
  values :: Dict{Symbol}
  count  :: Dict{Symbol, Int}

  Variables(names) = new(names, Dict{Symbol, Any}(), Dict{Symbol, Int}())
end

function match_variable!(v::Variables, name::Symbol, value)
  name in v.names || return true

  haskey(v.values, name)?
    (v.values[name] == value? (v.count[name] += 1; true) : false) :
    (v.values[name] =  value; (v.count[name]  = 1; true))
end

function unmatch_variable!(v::Variables, names)
  for name in names
  	if v.count[name] >  1
  	   v.count[name] -= 1
  	else
  	   delete!(v.count,  name)
  	   delete!(v.values, name)
  	end
  end
end

end
