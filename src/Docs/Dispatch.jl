#-----------------------------------------------------------------------------------
# Dispatch.Structure;
#-----------------------------------------------------------------------------------
import ..Dispatch.Structure: MetaMethod, MetaMethodTable, MetaMethodError

"""
`MetaMethod` associates a pattern tree to a function. They populate
`MetaMethodTable`s.

"""
MetaMethod;

"""
`MetaMethodTable`s are collections of `MetaMethod`s, they associate
each one with both a index and a label.

Relevant functions:
- `getmethod`
- `newmethod!`
- `removemethod!`
- `prefermethod!`

"""
MetaMethodTable;

"""
`MetaMethodError`

Error that is thrown when a method is not found in a `MetaMethodTable`.

"""
MetaMethodError;

#-----------------------------------------------------------------------------------
# Dispatch.TableManipulation;
#-----------------------------------------------------------------------------------
import ..Dispatch.TableManipulation: getmethod, newmethod!, removemethod!, prefermethod!, whichmethod,
                                     methodconflicts, set_conflict_warnings

"""
`getmethod(table, parameters) -> MetaMethod`

Find the method whose pattern matches the given parameters.
Throws a `MetaMethodError` if no method is found.

"""
getmethod;

"""
`newmethod!(table, pattern, body, mod[, label])`

Creates a new method in `table` that matches `pattern` and executes `body`.
Also takes a module that will be used in the evaluation of `pattern` and `body`.
An optionally given `label` will be associated with the new method, so that it
can be accessed with `table.labels[label]`.

"""
newmethod!;

"""
`removemethod!(table, label)`

Removes the method associated with `label` from `table`.

`removemethod!(table, pattern)`

Same as above, but associates the method with a pattern instead.


"""
removemethod!;

"""
`prefermethod!(table, label1, label2)`

Gives priority to the method associated with `label1` over the one associated with `label2`.
Used to resolve ambiguities between conflicting methods. Will print a warning if the
methods passed don't conflict.

`prefermethod!(table, pattern1, pattern2)`

Same as above, but associates the methods with the given patterns instead.

"""
prefermethod!;

"""
`whichmethod(table, parameters)`

Same as `getmethod`, but doesn't throw an error if no method is found.

"""
whichmethod;

"""
`methodconflicts(table)`

Finds and prints any conflict between the methods in `table`.

"""
methodconflicts;

"""
`set_conflict_warnings(Symbol)`

Sets the behaviour of conflict warnings.

| option       | meaning                                                          |
|:-------------|:-----------------------------------------------------------------|
|`:yes`        | Will always print a warning if a new method introduces conflicts.|
|`:interactive`| Only prints warnings in interactive mode.                        |
|`:no`         | Never print conflict warnings.                                   |

The default is `:interactive`.

"""
set_conflict_warnings;

#-----------------------------------------------------------------------------------
# Dispatch.TopMetaTables;
#-----------------------------------------------------------------------------------
import ..Dispatch.TopMetaTables: TopMetaTable,  init_module_table!, init_metatable!, get_metatable, import_metatable!

"""
`TopMetaTable`s keeps track of a collection of `MetaMethodTable`s for each module.
They are used to implement `@macromethod` and `@metafunction`.

"""
TopMetaTable;


"""
`init_module_table!(toptable, mod)`

Initializes the table collection for the module `mod`.

"""
init_module_table!;


"""
`init_metatable!(toptable, mod, key, name) -> MetaMethodTable`

Initializes a metatable, putting it into `toptable[mod][key]`.
Calls `init_module_table!(table, mod)` before doing anything else.

"""
init_metatable!;

"""
`get_metatable(toptable, mod, key) -> MetaMethodTable`

Finds the metatable associated with the symbol `key` and the module `mod`.
If no table is found, throw a `MetaTableNotFoundError`.
"""
get_metatable;

"""
`import_metatable(toptable, key, from[, to=current_module()])`

Associates a metatable to a new module.

"""
import_metatable;

#-----------------------------------------------------------------------------------
# Dispatch.Applications;
#-----------------------------------------------------------------------------------
import ..Dispatch.Applications: @macromethod, @metafunction, @metadestruct, @metadispatch, Applications

"""
`@macromethod name(patterns...) body`  
`@macromethod name(patterns...) = body`

Creates a extensible macro that matches and destructures the given patterns.

For examples see the [`/examples`](../../examples) directory or the [dispatch tests](../../test/dispatch.jl).
"""
:(Applications.@macromethod);

"""
`@metafunction name(patterns...) body`  
`@metafunction name(patterns...) = body`

Creates a function that dispatches on expression patterns.

For examples see the [`/examples`](../../examples) directory or the [dispatch tests](../../test/dispatch.jl).

"""
:(Applications.@metafunction);

"""
`@metadestruct let ...;  ... end`  
`@metadestruct macro m(...) ... end`  
`@metadestruct (...,) -> ...`  
`@metadestruct f(...) = ...`  
`@metadestruct function f(...) ... end`

Adds expression destructuring to its parameter.

Related:
- `@letds`
- `@macrods`
- `@anonds`
- `@funds`

"""
:(Applications.@metadestruct);

"""
`@metadispatch macro m(...) ... end`  
`@metadispatch function f(...) ... end`  
`@metadispatch f(...) = ...`

Adds expression destructuring and dispatch to its parameter.

Related:
- `@macromethod`
- `@metafunction`

"""
:(Applications.@metadispatch);

#-----------------------------------------------------------------------------------
# Dispatch.MetaModule;
#-----------------------------------------------------------------------------------
import ..Dispatch.MetaModule: @metamodule, MetaModule

"""
`@metamodule import Module.Path.name`

Import the metatable `name` from `Module.Path`. This allows the metatable to
be extended with new metamethods.

example:
```
module A
using ExpressionPatterns.Dispatch
  @macromethod f(x) 1
end

module B
using ExpressionPatterns.Dispatch
  @metamodule import ..A.@f
  @macromethod f(x,y) 2
end

A.@f(x)   == 1
A.@f(x,y) == 2

```

`@metamodule export name`

Exports the metatable `name` from the current module M so that `@metamodule importall M` will import it.


`@metamodule importall Module.Path`

Import all exported metatables from `Module.Path`.

"""
:(MetaModule.@metamodule);