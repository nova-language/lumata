defmodule Lumata.Ast.Types do
  alias TypeSystem

  @namespace "Lumata.Ast"

  @doc false
  # Helper to add a type definition to the context, raising on error for easier debugging during setup
  defp add_type_def(ctx, name, type_def) do
    case TypeSystem.add_type(ctx, name, type_def) do
      {:ok, new_ctx} -> new_ctx
      {:error, reason} -> raise "Failed to add type #{name}: #{reason}"
    end
  end

  @doc """
  Adds all Lumata AST type definitions to the TypeSystem context.
  """
  def add_ast_types(ctx) do
    # 1. Add placeholder Primitive types for union types and forward references.
    #    These will be re-defined as Data types later if they are true sum types.
    #    For 'Expression', 'LiteralValue', 'Pattern', 'DoStatement', we keep them as Primitive
    #    because the original spec uses a discriminated union of records, which doesn't
    #    perfectly map to TypeSystem's 'Data' type (which expects explicit constructors).
    ctx =
      add_type_def(ctx, "Expression", %{
        name: "Expression",
        type: "Primitive",
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Pattern", %{
        name: "Pattern",
        type: "Primitive",
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "LiteralValue", %{
        name: "LiteralValue",
        type: "Primitive",
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "CasePattern", %{
        name: "CasePattern",
        type: "Primitive",
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "DoStatement", %{
        name: "DoStatement",
        type: "Primitive",
        namespace: @namespace
      })

    # Define Data types (enums/sum types).
    ctx =
      add_type_def(ctx, "BinaryOperator", %{
        name: "BinaryOperator",
        type: "Data",
        constructors: [
          "Add",
          "Subtract",
          "Multiply",
          "Divide",
          "Modulo",
          "Power",
          "Equal",
          "NotEqual",
          "LessThan",
          "LessThanOrEqual",
          "GreaterThan",
          "GreaterThanOrEqual",
          "And",
          "Or",
          "Cons",
          "Append",
          "Compose",
          "Pipe"
        ],
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "UnaryOperator", %{
        name: "UnaryOperator",
        type: "Data",
        constructors: [
          "Negate",
          "Not",
          "Length",
          "Head",
          "Tail",
          "Reverse"
        ],
        namespace: @namespace
      })

    # 2. Define helper record types used within other definitions.
    ctx =
      add_type_def(ctx, "LetBinding", %{
        name: "LetBinding",
        type: "Record",
        fields: %{
          "name" => "String",
          "value" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "LambdaParameter", %{
        name: "LambdaParameter",
        type: "Record",
        fields: %{
          "name" => "String",
          # Assuming type here is a string name
          "type" => "String"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "CatchPattern", %{
        name: "CatchPattern",
        type: "Record",
        fields: %{
          "pattern" => "Pattern",
          "handler" => "Expression"
        },
        namespace: @namespace
      })

    # 3. Define specific literal types (Records)
    ctx =
      add_type_def(ctx, "IntLiteral", %{
        name: "IntLiteral",
        type: "Record",
        fields: %{"value" => "Int"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "StringLiteral", %{
        name: "StringLiteral",
        type: "Record",
        fields: %{"value" => "String"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "BoolLiteral", %{
        name: "BoolLiteral",
        type: "Record",
        fields: %{"value" => "Bool"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "ListLiteral", %{
        name: "ListLiteral",
        type: "Record",
        fields: %{"elements" => %{constructor: "List", vars: ["Expression"]}},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "RecordLiteral", %{
        name: "RecordLiteral",
        type: "Record",
        fields: %{"fields" => %{constructor: "Map", vars: ["String", "Expression"]}},
        namespace: @namespace
      })

    # 4. Define specific pattern types (Records)
    ctx =
      add_type_def(ctx, "WildcardPattern", %{
        name: "WildcardPattern",
        type: "Record",
        # No fields
        fields: %{},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "VariablePattern", %{
        name: "VariablePattern",
        type: "Record",
        fields: %{"name" => "String"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "LiteralPattern", %{
        name: "LiteralPattern",
        type: "Record",
        fields: %{"value" => "LiteralValue"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "ConstructorPattern", %{
        name: "ConstructorPattern",
        type: "Record",
        fields: %{
          "constructor" => "String",
          "args" => %{constructor: "List", vars: ["Pattern"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "RecordPattern", %{
        name: "RecordPattern",
        type: "Record",
        fields: %{"fields" => %{constructor: "Map", vars: ["String", "Pattern"]}},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "ListPattern", %{
        name: "ListPattern",
        type: "Record",
        fields: %{
          "elements" => %{constructor: "List", vars: ["Pattern"]},
          # Replaced nullable with Maybe
          "tail" => %{constructor: "Maybe", vars: ["Pattern"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "AsPattern", %{
        name: "AsPattern",
        type: "Record",
        fields: %{
          "pattern" => "Pattern",
          "name" => "String"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "OrPattern", %{
        name: "OrPattern",
        type: "Record",
        fields: %{"patterns" => %{constructor: "List", vars: ["Pattern"]}},
        namespace: @namespace
      })

    # 5. Define specific do_statement types (Records)
    ctx =
      add_type_def(ctx, "Bind", %{
        name: "Bind",
        type: "Record",
        fields: %{
          "name" => "String",
          "value" => "Expression"
        },
        namespace: @namespace
      })

    # Renamed from "Expression" to avoid clash with Expression type
    ctx =
      add_type_def(ctx, "ExpressionStatement", %{
        name: "ExpressionStatement",
        type: "Record",
        fields: %{"expr" => "Expression"},
        namespace: @namespace
      })

    # 6. Define main AST types (Records)
    ctx =
      add_type_def(ctx, "QualifiedIdentifier", %{
        name: "QualifiedIdentifier",
        type: "Record",
        fields: %{
          # Replaced nullable with Maybe
          "namespace" => %{constructor: "Maybe", vars: ["String"]},
          "name" => "String"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Variable", %{
        name: "Variable",
        type: "Record",
        fields: %{"name" => "String"},
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "FunctionCall", %{
        name: "FunctionCall",
        type: "Record",
        fields: %{
          "function" => "QualifiedIdentifier",
          "arguments" => %{constructor: "List", vars: ["Expression"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "FieldAccess", %{
        name: "FieldAccess",
        type: "Record",
        fields: %{
          "target" => "Expression",
          "field" => "String"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "ListAccess", %{
        name: "ListAccess",
        type: "Record",
        fields: %{
          "target" => "Expression",
          "index" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "BinaryOp", %{
        name: "BinaryOp",
        type: "Record",
        fields: %{
          "operator" => "BinaryOperator",
          "left" => "Expression",
          "right" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "UnaryOp", %{
        name: "UnaryOp",
        type: "Record",
        fields: %{
          "operator" => "UnaryOperator",
          "operand" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "RecordCreation", %{
        name: "RecordCreation",
        type: "Record",
        fields: %{
          "record_type" => "String",
          "fields" => %{constructor: "Map", vars: ["String", "Expression"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "RecordUpdate", %{
        name: "RecordUpdate",
        type: "Record",
        fields: %{
          "target" => "Expression",
          "updates" => %{constructor: "Map", vars: ["String", "Expression"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "ConstructorCall", %{
        name: "ConstructorCall",
        type: "Record",
        fields: %{
          "constructor" => "String",
          "arguments" => %{constructor: "List", vars: ["Expression"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Case", %{
        name: "Case",
        type: "Record",
        fields: %{
          "scrutinee" => "Expression",
          "patterns" => %{constructor: "List", vars: ["CasePattern"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "CasePattern", %{
        name: "CasePattern",
        type: "Record",
        fields: %{
          "pattern" => "Pattern",
          # Replaced nullable with Maybe
          "guard" => %{constructor: "Maybe", vars: ["Expression"]},
          "expression" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "If", %{
        name: "If",
        type: "Record",
        fields: %{
          "condition" => "Expression",
          "then_expr" => "Expression",
          "else_expr" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Let", %{
        name: "Let",
        type: "Record",
        fields: %{
          "bindings" => %{constructor: "List", vars: ["LetBinding"]},
          "body" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Lambda", %{
        name: "Lambda",
        type: "Record",
        fields: %{
          "parameters" => %{constructor: "List", vars: ["LambdaParameter"]},
          "body" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Map", %{
        name: "Map",
        type: "Record",
        fields: %{
          "collection" => "Expression",
          "iterator" => "String",
          "transform" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Filter", %{
        name: "Filter",
        type: "Record",
        fields: %{
          "collection" => "Expression",
          "iterator" => "String",
          "predicate" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Fold", %{
        name: "Fold",
        type: "Record",
        fields: %{
          "collection" => "Expression",
          "accumulator" => "Expression",
          "iterator" => "String",
          "acc_name" => "String",
          "transform" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Try", %{
        name: "Try",
        type: "Record",
        fields: %{
          "body" => "Expression",
          "catch_patterns" => %{constructor: "List", vars: ["CatchPattern"]}
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "Do", %{
        name: "Do",
        type: "Record",
        fields: %{
          "statements" => %{constructor: "List", vars: ["DoStatement"]},
          "return" => "Expression"
        },
        namespace: @namespace
      })

    ctx =
      add_type_def(ctx, "TypeAnnotation", %{
        name: "TypeAnnotation",
        type: "Record",
        fields: %{
          "expr" => "Expression",
          "annotation" => "String"
        },
        namespace: @namespace
      })

    ctx
  end
end
