# Helpers to aid in constructing class definitions
immutable ClassId end

type ClassConstructor
  statements
  param_defs
  method_defs
  new_args
  arguments
  ClassConstructor() = new([],[],[],[],:undef)
end

type ClassInfo
  constructor::ClassConstructor
  parameters
  undefined
  nonfunctions
  ClassInfo() = new(ClassConstructor(), [], [], [])
end

function make_constructor(name, info, constructor_info::ClassConstructor)
  args  = constructor_info.arguments
  stats = constructor_info.statements

  statements  = args == :undef? map(make_def, info.undefined) : stats
  arguments   = args == :undef? info.undefined : args
  param_defs  = constructor_info.param_defs
  method_defs = constructor_info.method_defs
  new_args    = constructor_info.new_args

  :(function $name($(arguments...))
      this = $name(ClassId())
      $(param_defs...)
      $(method_defs...)
      $(statements...)
      this
    end)
end


# unrelated to the metadispatch part of the definition

abstract Object

immutable Method{T <: Object}
  func  :: Function
end
(m::Method)(args...) = m.func(args...)

class_field_values(obj) =
  filter(x->!isa(x, Method), map(x->getfield(obj, x), fieldnames(obj)))

function Base.show{T <: Object}(io::IO, obj::T)
  print("$T(")

  fields = class_field_values(obj)
  for i in eachindex(fields)
  	print(fields[i])
  	if i != length(fields)
  	  print(",")
  	end
  end

  print(")")
end
