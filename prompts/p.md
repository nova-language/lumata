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

types can have type parameters:
Maybe{a} = Just{a} | None
built in List{a}

in json:
```
"Face": {
          "constructor": "List",
          "vars": [
            {
              "constructor": "List",
              "vars": ["Color"]
            }
          ]
        }
```

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

```
{
"namespace": "cube",
"data_definitions": {},
"function_definitions": {
 "function_definition_example": {
    "name": "drawCubeFace",
    "args": [
      {"name": "side", "type": "CubeSide"},
      {"name": "state", "type": "CubeState"}
    ],
    "result_type": "Unit",
    "body_structure": [
      {identifier, type, expr}
    ]
  }
}
}
}
```


  @type qualified_identifier :: %{
    type: "QualifiedIdentifier",
    namespace: String.t() | nil,
    name: String.t()
  }

  @type literal_value :: 
    %{type: "IntLiteral", value: integer()} |
    %{type: "StringLiteral", value: String.t()} |
    %{type: "BoolLiteral", value: boolean()} |
    %{type: "ListLiteral", elements: [expression()]} |
    %{type: "RecordLiteral", fields: %{String.t() => expression()}}

  @type variable_reference :: %{
    type: "Variable",
    name: String.t()
  }

  @type function_call :: %{
    type: "FunctionCall",
    function: qualified_identifier(),
    arguments: [expression()]
  }

  @type field_access :: %{
    type: "FieldAccess", 
    target: expression(),
    field: String.t()
  }

  @type list_access :: %{
    type: "ListAccess",
    target: expression(),
    index: expression()
  }

  @type binary_operation :: %{
    type: "BinaryOp",
    operator: binary_operator(),
    left: expression(),
    right: expression()
  }

  @type unary_operation :: %{
    type: "UnaryOp", 
    operator: unary_operator(),
    operand: expression()
  }

  @type binary_operator ::
    # Arithmetic
    "Add" | "Subtract" | "Multiply" | "Divide" | "Modulo" | "Power" |
    # Comparison  
    "Equal" | "NotEqual" | "LessThan" | "LessThanOrEqual" | 
    "GreaterThan" | "GreaterThanOrEqual" |
    # Logical
    "And" | "Or" |
    # List operations
    "Cons" | "Append" |
    # Composition
    "Compose" | "Pipe"

  @type unary_operator ::
    "Negate" | "Not" | "Length" | "Head" | "Tail" | "Reverse"

  @type record_creation :: %{
    type: "RecordCreation",
    record_type: String.t(),
    fields: %{String.t() => expression()}
  }

  @type record_update :: %{
    type: "RecordUpdate", 
    target: expression(),
    updates: %{String.t() => expression()}
  }

  @type constructor_call :: %{
    type: "ConstructorCall",
    constructor: String.t(),
    arguments: [expression()]
  }

  @type case_expression :: %{
    type: "Case",
    scrutinee: expression(),
    patterns: [case_pattern()]
  }

  @type case_pattern :: %{
    pattern: pattern(),
    guard: expression() | nil,
    expression: expression()
  }

  @type pattern ::
    %{type: "WildcardPattern"} |
    %{type: "VariablePattern", name: String.t()} |
    %{type: "LiteralPattern", value: literal_value()} |
    %{type: "ConstructorPattern", constructor: String.t(), args: [pattern()]} |
    %{type: "RecordPattern", fields: %{String.t() => pattern()}} |
    %{type: "ListPattern", elements: [pattern()], tail: pattern() | nil} |
    %{type: "AsPattern", pattern: pattern(), name: String.t()} |
    %{type: "OrPattern", patterns: [pattern()]}

  @type conditional_expression :: %{
    type: "If",
    condition: expression(),
    then_expr: expression(),
    else_expr: expression()
  }

  @type let_expression :: %{
    type: "Let",
    bindings: [%{name: String.t(), value: expression()}],
    body: expression()
  }

  @type lambda_expression :: %{
    type: "Lambda",
    parameters: [%{name: String.t(), type: String.t()}],
    body: expression()
  }

  @type map_expression :: %{
    type: "Map",
    collection: expression(),
    iterator: String.t(),
    transform: expression()
  }

  @type filter_expression :: %{
    type: "Filter", 
    collection: expression(),
    iterator: String.t(),
    predicate: expression()
  }

  @type fold_expression :: %{
    type: "Fold",
    collection: expression(),
    accumulator: expression(),
    iterator: String.t(),
    acc_name: String.t(),
    transform: expression()
  }

  @type try_expression :: %{
    type: "Try",
    body: expression(),
    catch_patterns: [%{
      pattern: pattern(),
      handler: expression()
    }]
  }

  @type do_expression :: %{
    type: "Do",
    statements: [do_statement()],
    return: expression()
  }

  @type do_statement ::
    %{type: "Bind", name: String.t(), value: expression()} |
    %{type: "Expression", expr: expression()}

  @type type_annotation :: %{
    type: "TypeAnnotation",
    expr: expression(),
    annotation: String.t()
  }

  @type expression ::
    literal_value() |
    variable_reference() |
    function_call() |
    field_access() |
    list_access() |
    binary_operation() |
    unary_operation() |
    record_creation() |
    record_update() |
    constructor_call() |
    case_expression() |
    conditional_expression() |
    let_expression() |
    lambda_expression() |
    map_expression() |
    filter_expression() |
    fold_expression() |
    try_expression() |
    do_expression() |
    type_annotation()

provide a rubik cube implementation
