Dispatch.Structure
==========

#### MetaMethod

`MetaMethod` associates a pattern tree to a function. They populate
[`MetaMethodTable`](./Dispatch.md#metamethodtable)s.

---
#### MetaMethodTable

`MetaMethodTable`s are collections of [`MetaMethod`](./Dispatch.md#metamethod)s, they associate
each one with both a index and a label.

Relevant functions:
- [`getmethod`](./Dispatch.md#getmethod)
- [`newmethod!`](./Dispatch.md#newmethod!)
- [`removemethod!`](./Dispatch.md#removemethod!)
- [`prefermethod!`](./Dispatch.md#prefermethod!)

---
#### MetaMethodError

`MetaMethodError`

Error that is thrown when a method is not found in a [`MetaMethodTable`](./Dispatch.md#metamethodtable).

---


Dispatch.TableManipulation
==========

#### getmethod

`getmethod(table, parameters) -> MetaMethod`

Find the method whose pattern matches the given parameters.
Throws a [`MetaMethodError`](./Dispatch.md#metamethoderror) if no method is found.

---
#### newmethod!

`newmethod!(table, pattern, body, mod[, label])`

Creates a new method in `table` that matches `pattern` and executes `body`.
Also takes a module that will be used in the evaluation of `pattern` and `body`.
An optionally given `label` will be associated with the new method, so that it
can be accessed with `table.labels[label]`.

---
#### removemethod!

`removemethod!(table, label)`

Removes the method associated with `label` from `table`.

`removemethod!(table, pattern)`

Same as above, but associates the method with a pattern instead.

---
#### prefermethod!

`prefermethod!(table, label1, label2)`

Gives priority to the method associated with `label1` over the one associated with `label2`.
Used to resolve ambiguities between conflicting methods. Will print a warning if the
methods passed don't conflict.

`prefermethod!(table, pattern1, pattern2)`

Same as above, but associates the methods with the given patterns instead.

---
#### whichmethod

`whichmethod(table, parameters)`

Same as [`getmethod`](./Dispatch.md#getmethod), but doesn't throw an error if no method is found.

---
#### methodconflicts

`methodconflicts(table)`

Finds and prints any conflict between the methods in `table`.

---
#### set_conflict_warnings

`set_conflict_warnings(Symbol)`

Sets the behaviour of conflict warnings.

| option       | meaning                                                          |
|:-------------|:-----------------------------------------------------------------|
|`:yes`        | Will always print a warning if a new method introduces conflicts.|
|`:interactive`| Only prints warnings in interactive mode.                        |
|`:no`         | Never print conflict warnings.                                   |

The default is `:interactive`.

---


Dispatch.TopMetaTables
==========

#### TopMetaTable

`TopMetaTable`s keeps track of a collection of [`MetaMethodTable`](./Dispatch.md#metamethodtable)s for each module.
They are used to implement [`@macromethod`](./Dispatch.md#macromethod) and [`@metafunction`](./Dispatch.md#metafunction).

---
#### init_module_table!

`init_module_table!(toptable, mod)`

Initializes the table collection for the module `mod`.

---
#### init_metatable!

`init_metatable!(toptable, mod, key, name) -> MetaMethodTable`

Initializes a metatable, putting it into `toptable[mod][key]`.
Calls `init_module_table!(table, mod)` before doing anything else.

---
#### get_metatable

`get_metatable(toptable, mod, key) -> MetaMethodTable`

Finds the metatable associated with the symbol `key` and the module `mod`.
If no table is found, throw a `MetaTableNotFoundError`.

---
#### import_metatable

`import_metatable(toptable, key, from[, to=current_module()])`

Associates a metatable to a new module.

---


Dispatch.Applications
==========

#### @macromethod

`@macromethod name(patterns...) body`  
`@macromethod name(patterns...) = body`

Creates a extensible macro that matches and destructures the given patterns.

For examples see the [`/examples`](../../examples) directory or the [dispatch tests](../../test/dispatch.jl).

---
#### @metafunction

`@metafunction name(patterns...) body`  
`@metafunction name(patterns...) = body`

Creates a function that dispatches on expression patterns.

For examples see the [`/examples`](../../examples) directory or the [dispatch tests](../../test/dispatch.jl).

---
#### @metadestruct

`@metadestruct let ...;  ... end`  
`@metadestruct macro m(...) ... end`  
`@metadestruct (...,) -> ...`  
`@metadestruct f(...) = ...`  
`@metadestruct function f(...) ... end`

Adds expression destructuring to its parameter.

Related:
- [`@letds`](./Destructuring.md#letds)
- [`@macrods`](./Destructuring.md#macrods)
- [`@anonds`](./Destructuring.md#anonds)
- [`@funds`](./Destructuring.md#funds)

---
#### @metadispatch

`@metadispatch macro m(...) ... end`  
`@metadispatch function f(...) ... end`  
`@metadispatch f(...) = ...`

Adds expression destructuring and dispatch to its parameter.

Related:
- [`@macromethod`](./Dispatch.md#macromethod)
- [`@metafunction`](./Dispatch.md#metafunction)

---


Dispatch.MetaModule
==========

#### @metamodule

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

---


