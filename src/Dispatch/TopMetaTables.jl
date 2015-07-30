module TopMetaTables
using  ...Dispatch.Structure
using  ...Dispatch.TableManipulation
export TopMetaTable, MetaTableNotFoundError, init_module_table!, init_metatable!, get_metatable,
       import_metatable!, export_metatable!, metatable_exports

immutable TopMetaTable
  values::ObjectIdDict
  TopMetaTable() = new(ObjectIdDict())
end

immutable MetaModuleTable
  values  :: Dict{Symbol, MetaMethodTable}
  exports :: Set{Symbol}
  MetaModuleTable() = new(Dict{Symbol, MetaMethodTable}(), Set{Symbol}())
end

Base.getindex(A::TopMetaTable,    mod::Module) = A.values[mod]
Base.getindex(A::MetaModuleTable, sym::Symbol) = A.values[sym]

Base.setindex!(A::TopMetaTable,    val, mod::Module) = A.values[mod] = val
Base.setindex!(A::MetaModuleTable, val, sym::Symbol) = A.values[sym] = val

Base.haskey(A::TopMetaTable,    mod::Module) = haskey(A.values, mod)
Base.haskey(A::MetaModuleTable, sym::Symbol) = haskey(A.values, sym)


immutable MetaTableNotFoundError <: Exception
  key::Symbol
  mod::Module
end


Base.showerror(io::IO, err::MetaTableNotFoundError) =
  println(STDERR, ("Unable to find metatable $(err.key) in $(err.mod)."))


function init_module_table!(toptable, mod)
  if !haskey(toptable, mod)
    toptable[mod] = MetaModuleTable()
  end
end

function init_metatable!(toptable, mod, key, name)
  init_module_table!(toptable, mod)
  if !haskey(toptable.values[mod], key)
    toptable[mod][key] = MetaMethodTable(name)
  end
end

function import_metatable!(toptable, tablekey, from, to=current_module())
  init_module_table!(toptable, from)
  init_module_table!(toptable, to)
  !haskey(toptable[from], tablekey) && return warn("Unable to find metatable $(tablekey) in $(from).")
   haskey(toptable[to],   tablekey) && return warn("Ignoring conflicting import of $(tablekey) in $(to).")

  toptable[to][tablekey] = toptable[from][tablekey]
end

function export_metatable!(toptable, tablekey, from=current_module())
  init_module_table!(toptable, from)
  push!(toptable[from].exports, tablekey)
end

function metatable_exports(toptable, mod::Module)
  init_module_table!(toptable, mod)
  toptable[mod].exports
end

function get_metatable(toptable, mod, key)
  init_module_table!(toptable, mod)
  !haskey(toptable[mod], key) && throw(MetaTableNotFoundError(key,mod))

  toptable.values[mod][key]
end

end