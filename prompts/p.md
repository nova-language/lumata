we are mocking code on a language, it transcompiles to javascript

arithmetic available: `+`, `-`, `*`, `/`
boolean algebra available "and", "or", "xor", "not"
L for let
Record creation: `{ key: value }`
L n1 = case n0 [
{pattern, expression},
{pattern, expression},
]
linked lists are available
 
type and data ADT definitions

Data Color [
Constructor Red
Constructor Black
]

no object, but record available

can destructure/pattern match list tail after n elements
```
[head|tail]
[n1, n2, n3 | tail]
```

these primitives are available:
[
reduce
fold
map
when
]

conditionals available in L evaluation

example
```
Function drawCubeFace 
Arg side CubeSide
Arg state CubeState
Result Unit
[
L1 ... = 
L2 ... =
L3 ... =
unit
]
```

write a 3d rubic cube game on it
