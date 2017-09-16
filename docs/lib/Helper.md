Helper
==========

#### Looping

`Looping(iterable)` creates an objects that permits
iterating an infinite repetition of `iterable`.

`current(L::Looping)` gets the current element.

`next!(L)` makes `current(L)` return the next object.
if the current object is the last of the iterable,
start from the beginning.

`restart!(L)` makes `current(L)` return the first
object.

---
#### current

`current(L::Looping)` returns the current element,
which can be changed through [`next!`](./Helper.md#next!) and [`restart!`](./Helper.md#restart!).

---
#### next!

Makes `current(L::Looping)` return the next object.
if the current object is the last of the iterable,
start from the beginning.

---
#### restart!

Makes `current(L::Looping)` return the first object.

---
#### unzip

`unzip(Iterable{Tuple{F,S}}) -> Tuple{Vector{F}, Vector{S}}`

Takes a iterable of the form `[(x₁,y₁), (x₂,y₂), ..., (xₙ, yₙ)]` and
transforms it  
in `([x₁, x₂, ..., xₙ], [y₁, y₂, ..., yₙ])`

---
#### remove

`remove((T -> Bool), Iterable{T}) -> Vector{T}`

Takes a function `f` and a collection and return that
collection with all elements `x` for which `f(x)` is
true removed.

---
#### is_line_number

`is_line_number(ex) -> Bool`

Returns true if `ex` represents a line number.
(`LineNumberNode` or `Expr(:line)`)

---
#### linesof

`linesof(Expr) -> Expr`

Takes a block expression and return all non-linenumber
elements from it.

---


