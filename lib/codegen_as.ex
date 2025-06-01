# --- AST Struct Definitions ---
# These defstructs allow pattern matching on the __struct__ field of AST nodes.
# In a real setup, these might be dynamically generated from the TypeSystem
# definitions or reside in a separate AST definition module.
# We're defining them here to make the example self-contained and runnable.

# Literal Types
defmodule Lumata.Ast.IntLiteral do
  defstruct value: nil
end

defmodule Lumata.Ast.StringLiteral do
  defstruct value: nil
end

defmodule Lumata.Ast.BoolLiteral do
  defstruct value: nil
end

defmodule Lumata.Ast.ListLiteral do
  defstruct elements: []
end

defmodule Lumata.Ast.RecordLiteral do
  defstruct fields: %{}
end

# Identifier/Variable Types
defmodule Lumata.Ast.Variable do
  defstruct name: nil
end

defmodule Lumata.Ast.QualifiedIdentifier do
  defstruct namespace: nil, name: nil
end

# Operator Types
defmodule Lumata.Ast.BinaryOp do
  defstruct operator: nil, left: nil, right: nil
end

defmodule Lumata.Ast.UnaryOp do
  defstruct operator: nil, operand: nil
end

# Call/Access Types
defmodule Lumata.Ast.FunctionCall do
  defstruct function: nil, arguments: []
end

defmodule Lumata.Ast.ConstructorCall do
  defstruct constructor: nil, arguments: []
end

defmodule Lumata.Ast.RecordCreation do
  defstruct record_type: nil, fields: %{}
end

defmodule Lumata.Ast.RecordUpdate do
  defstruct target: nil, updates: %{}
end

defmodule Lumata.Ast.FieldAccess do
  defstruct target: nil, field: nil
end

defmodule Lumata.Ast.ListAccess do
  defstruct target: nil, index: nil
end

# Control Flow Types
defmodule Lumata.Ast.Case do
  defstruct scrutinee: nil, patterns: []
end

defmodule Lumata.Ast.If do
  defstruct condition: nil, then_expr: nil, else_expr: nil
end

defmodule Lumata.Ast.Let do
  defstruct bindings: [], body: nil
end

defmodule Lumata.Ast.Lambda do
  defstruct parameters: [], body: nil
end

defmodule Lumata.Ast.Try do
  defstruct body: nil, catch_patterns: []
end

defmodule Lumata.Ast.Do do
  defstruct statements: [], return: nil
end

# Collection Operation Types
defmodule Lumata.Ast.Map do
  defstruct collection: nil, iterator: nil, transform: nil
end

defmodule Lumata.Ast.Filter do
  defstruct collection: nil, iterator: nil, predicate: nil
end

defmodule Lumata.Ast.Fold do
  defstruct collection: nil, accumulator: nil, iterator: nil, acc_name: nil, transform: nil
end

# Other Types
defmodule Lumata.Ast.TypeAnnotation do
  defstruct expr: nil, annotation: nil
end

# Helper Structs for complex types (Let, Lambda, Case, Try)
defmodule Lumata.Ast.LetBinding do
  defstruct name: nil, value: nil
end

# 'type' field is a string, e.g., "Int", "String"
defmodule Lumata.Ast.LambdaParameter do
  defstruct name: nil, type: nil
end

defmodule Lumata.Ast.CatchPattern do
  defstruct pattern: nil, handler: nil
end

defmodule Lumata.Ast.CasePattern do
  defstruct pattern: nil, guard: nil, expression: nil
end

# Do Statement Structs
defmodule Lumata.Ast.Bind do
  defstruct name: nil, value: nil
end

defmodule Lumata.Ast.ExpressionStatement do
  defstruct expr: nil
end

# Pattern Structs
defmodule Lumata.Ast.WildcardPattern do
  defstruct []
end

defmodule Lumata.Ast.VariablePattern do
  defstruct name: nil
end

defmodule Lumata.Ast.LiteralPattern do
  defstruct value: nil
end

# args is a list of Patterns
defmodule Lumata.Ast.ConstructorPattern do
  defstruct constructor: nil, args: []
end

# fields is a map of String -> Pattern
defmodule Lumata.Ast.RecordPattern do
  defstruct fields: %{}
end

# elements: list of Pattern, tail: Maybe<Pattern>
defmodule Lumata.Ast.ListPattern do
  defstruct elements: [], tail: nil
end

defmodule Lumata.Ast.AsPattern do
  defstruct pattern: nil, name: nil
end

defmodule Lumata.Ast.OrPattern do
  defstruct patterns: []
end

defmodule Lumata.CodeGen.AsRenderer do
  @moduledoc """
  Renders Lumata AST (represented as Elixir structs) into AssemblyScript code.
  """

  @doc """
  Renders a Lumata AST node into an AssemblyScript code string.
  """
  def render(ast_node) do
    case ast_node do
      # Literals
      %Lumata.Ast.IntLiteral{value: value} ->
        "#{value}"

      %Lumata.Ast.StringLiteral{value: value} ->
        "\"#{value}\""

      %Lumata.Ast.BoolLiteral{value: value} ->
        "#{value}"

      %Lumata.Ast.ListLiteral{elements: elements} ->
        "[#{render_list(elements)}]"

      %Lumata.Ast.RecordLiteral{fields: fields} ->
        "{ #{render_record_fields(fields)} }"

      # Variables
      %Lumata.Ast.Variable{name: name} ->
        "#{name}"

      %Lumata.Ast.QualifiedIdentifier{namespace: namespace, name: name} ->
        if namespace, do: "#{namespace}.#{name}", else: name

      # Operators
      %Lumata.Ast.BinaryOp{operator: op, left: left, right: right} ->
        render_binary_op(op, left, right)

      %Lumata.Ast.UnaryOp{operator: op, operand: operand} ->
        render_unary_op(op, operand)

      # Function/Constructor Calls
      %Lumata.Ast.FunctionCall{function: func_ident, arguments: args} ->
        "#{render(func_ident)}(#{render_list(args)})"

      %Lumata.Ast.ConstructorCall{constructor: constructor_name, arguments: args} ->
        # Assumes constructors map to class instantiations (e.g., `new SomeConstructor(arg1, arg2)`)
        "new #{constructor_name}(#{render_list(args)})"

      # Record/Field Operations
      %Lumata.Ast.RecordCreation{record_type: type_name, fields: fields} ->
        # Assumes a class constructor taking an object literal for fields (e.g., `new MyRecord({ field1: value })`)
        "new #{type_name}({ #{render_record_fields(fields)} })"

      %Lumata.Ast.RecordUpdate{target: target, updates: updates} ->
        # For immutable updates, use spread syntax to create a new object
        "({ ...#{render(target)}, #{render_record_fields(updates)} })"

      %Lumata.Ast.FieldAccess{target: target, field: field} ->
        "#{render(target)}.#{field}"

      %Lumata.Ast.ListAccess{target: target, index: index} ->
        "#{render(target)}[#{render(index)}]"

      # Control Flow
      %Lumata.Ast.If{condition: cond, then_expr: then_e, else_expr: else_e} ->
        """
        ((_ => {
          if (#{render(cond)}) {
            return #{render(then_e)};
          } else {
            return #{render(else_e)};
          }
        })())
        """

      %Lumata.Ast.Case{scrutinee: scrutinee, patterns: patterns} ->
        render_case(scrutinee, patterns)

      %Lumata.Ast.Let{bindings: bindings, body: body} ->
        let_vars =
          Enum.map(bindings, fn %Lumata.Ast.LetBinding{name: name, value: value} ->
            "const #{name} = #{render(value)};"
          end)
          |> Enum.join("\n  ")

        """
        ((_ => {
          #{let_vars}
          return #{render(body)};
        })())
        """

      %Lumata.Ast.Lambda{parameters: params, body: body} ->
        param_list =
          Enum.map(params, fn %Lumata.Ast.LambdaParameter{name: name, type: type_name} ->
            "#{name}: #{type_name}"
          end)
          |> Enum.join(", ")

        "(#{param_list}) => {\n  return #{render(body)};\n}"

      %Lumata.Ast.Try{body: body, catch_patterns: catch_patterns} ->
        render_try(body, catch_patterns)

      %Lumata.Ast.Do{statements: statements, return: return_expr} ->
        do_statements =
          Enum.map(statements, fn statement ->
            case statement do
              %Lumata.Ast.Bind{name: name, value: value} ->
                "const #{name} = #{render(value)};"

              %Lumata.Ast.ExpressionStatement{expr: expr} ->
                "#{render(expr)};"

              _ ->
                raise "Unhandled do statement type: #{inspect(statement)}"
            end
          end)
          |> Enum.join("\n  ")

        """
        ((_ => {
          #{do_statements}
          return #{render(return_expr)};
        })())
        """

      # Collection operations
      %Lumata.Ast.Map{collection: coll, iterator: iter, transform: transform} ->
        "#{render(coll)}.map((#{iter}) => #{render(transform)})"

      %Lumata.Ast.Filter{collection: coll, iterator: iter, predicate: pred} ->
        "#{render(coll)}.filter((#{iter}) => #{render(pred)})"

      %Lumata.Ast.Fold{
        collection: coll,
        accumulator: acc_init,
        iterator: iter,
        acc_name: acc_name,
        transform: transform
      } ->
        "#{render(coll)}.reduce((#{acc_name}, #{iter}) => #{render(transform)}, #{render(acc_init)})"

      # Type Annotation
      %Lumata.Ast.TypeAnnotation{expr: expr, annotation: annotation} ->
        "(#{render(expr)} as #{annotation})"

      _ ->
        raise "Unhandled AST node type: #{inspect(ast_node)}"
    end
  end

  # --- Private Helpers ---

  defp render_list(list) do
    Enum.map(list, &render/1)
    |> Enum.join(", ")
  end

  defp render_record_fields(fields) do
    Enum.map(fields, fn {key, value} ->
      "\"#{key}\": #{render(value)}"
    end)
    |> Enum.join(", ")
  end

  # Renders binary operations, handling specific Lumata operators.
  defp render_binary_op(op, left, right) do
    left_str = render(left)
    right_str = render(right)

    case op do
      "Add" -> "(#{left_str} + #{right_str})"
      "Subtract" -> "(#{left_str} - #{right_str})"
      "Multiply" -> "(#{left_str} * #{right_str})"
      "Divide" -> "(#{left_str} / #{right_str})"
      "Modulo" -> "(#{left_str} % #{right_str})"
      # Math.pow for exponentiation in AS
      "Power" -> "Math.pow(#{left_str}, #{right_str})"
      "Equal" -> "(#{left_str} === #{right_str})"
      "NotEqual" -> "(#{left_str} !== #{right_str})"
      "LessThan" -> "(#{left_str} < #{right_str})"
      "LessThanOrEqual" -> "(#{left_str} <= #{right_str})"
      "GreaterThan" -> "(#{left_str} > #{right_str})"
      "GreaterThanOrEqual" -> "(#{left_str} >= #{right_str})"
      "And" -> "(#{left_str} && #{right_str})"
      "Or" -> "(#{left_str} || #{right_str})"
      # Immutable prepend to list
      "Cons" -> "[#{left_str}].concat(#{right_str})"
      "Append" -> "(#{left_str}).concat(#{right_str})"
      # Function composition: (f . g)(x) = f(g(x))
      "Compose" -> "((x: any) => #{right_str}(#{left_str}(x)))"
      # Function piping: (f |> g)(x) = g(f(x))
      "Pipe" -> "((x: any) => #{right_str}(#{left_str}(x)))"
      _ -> raise "Unknown binary operator: #{op}"
    end
  end

  # Renders unary operations, handling specific Lumata operators.
  defp render_unary_op(op, operand) do
    operand_str = render(operand)

    case op do
      "Negate" -> "(-#{operand_str})"
      "Not" -> "(!#{operand_str})"
      "Length" -> "(#{operand_str}.length)"
      "Head" -> "(#{operand_str}[0])"
      "Tail" -> "(#{operand_str}.slice(1))"
      # Create copy to avoid mutation
      "Reverse" -> "(Array.from(#{operand_str}).reverse())"
      _ -> raise "Unknown unary operator: #{op}"
    end
  end

  @doc false
  # Helper for rendering patterns within a case or try/catch context.
  # Returns `{:ok, condition_string, binding_strings_list}`.
  # `binding_strings_list` contains `const varName = matchedValue;` strings.
  defp render_pattern_match_with_bindings(pattern, target_var_name) do
    case pattern do
      %Lumata.Ast.WildcardPattern{} ->
        {:ok, "true", []}

      %Lumata.Ast.VariablePattern{name: name} ->
        # A variable pattern always matches. The binding is handled by `const` inside the if block.
        {:ok, "true", ["const #{name} = #{target_var_name};"]}

      %Lumata.Ast.LiteralPattern{value: value} ->
        {:ok, "#{target_var_name} === #{render(value)}", []}

      %Lumata.Ast.ConstructorPattern{constructor: constr_name, args: args} ->
        # Assumes constructors map to classes in AS.
        # Example: `Ok(value)` -> `new Ok(value)`. Constructor fields might be `value` or `arg0`.
        # This is a simplification; a full system would require knowing the class structure.
        match_cond = "#{target_var_name} instanceof #{constr_name}"
        conditions = [match_cond]
        all_bindings = []

        # Assuming constructor arguments are accessible as `.value` for single-arg constructors,
        # or `.arg0`, `.arg1` for multiple arguments. Adjust as per AS AST class definitions.
        Enum.each(args, fn arg_pat ->
          # Recursive call for nested patterns. This assumes `value` field for arguments.
          # For multiple arguments, you would need to map them to specific fields.
          {:ok, cond, bindings} =
            render_pattern_match_with_bindings(arg_pat, "#{target_var_name}.value")

          conditions = conditions ++ [cond]
          all_bindings = all_bindings ++ bindings
        end)

        {:ok, Enum.join(conditions, " && "), all_bindings}

      %Lumata.Ast.RecordPattern{fields: fields} ->
        conditions = ["#{target_var_name} !== null"]
        all_bindings = []

        Enum.each(fields, fn {field_name, field_pattern} ->
          {:ok, cond, bindings} =
            render_pattern_match_with_bindings(field_pattern, "#{target_var_name}.#{field_name}")

          conditions = conditions ++ [cond]
          all_bindings = all_bindings ++ bindings
        end)

        {:ok, Enum.join(conditions, " && "), all_bindings}

      %Lumata.Ast.ListPattern{elements: elements, tail: tail} ->
        conditions = ["Array.isArray(#{target_var_name})"]
        all_bindings = []

        # Element checks for fixed elements
        Enum.with_index(elements, fn elem_pat, i ->
          {:ok, cond, bindings} =
            render_pattern_match_with_bindings(elem_pat, "#{target_var_name}[#{i}]")

          conditions = conditions ++ [cond]
          all_bindings = all_bindings ++ bindings
        end)

        # Length check: exact if no tail, or minimum if tail present
        length_check =
          if is_nil(tail) || (%Lumata.Ast.WildcardPattern{} = tail) do
            "#{target_var_name}.length === #{length(elements)}"
          else
            "#{target_var_name}.length >= #{length(elements)}"
          end

        conditions = conditions ++ [length_check]

        # Tail check (if tail exists)
        if tail do
          # The tail pattern is matched against a slice of the array
          {:ok, tail_cond, tail_bindings} =
            render_pattern_match_with_bindings(
              tail,
              "#{target_var_name}.slice(#{length(elements)})"
            )

          conditions = conditions ++ [tail_cond]
          all_bindings = all_bindings ++ tail_bindings
        end

        {:ok, Enum.join(conditions, " && "), all_bindings}

      %Lumata.Ast.AsPattern{pattern: inner_pattern, name: name} ->
        {:ok, inner_cond, inner_bindings} =
          render_pattern_match_with_bindings(inner_pattern, target_var_name)

        # The 'as' pattern binds the whole matched value to 'name'
        {:ok, inner_cond, ["const #{name} = #{target_var_name};" | inner_bindings]}

      %Lumata.Ast.OrPattern{patterns: patterns} ->
        # For OrPattern, bindings are tricky: only the *first* matching branch's bindings apply.
        # This simplified renderer doesn't handle merging complex bindings from OR branches;
        # it just produces the boolean condition. Bindings from sub-patterns are applied only if
        # the overall `Case` block's condition (which contains the OR) is met.
        or_parts =
          Enum.map(patterns, fn p ->
            {:ok, cond, _} = render_pattern_match_with_bindings(p, target_var_name)
            "(#{cond})"
          end)

        # No direct bindings from OrPattern itself
        {:ok, Enum.join(or_parts, " || "), []}

      _ ->
        raise "Unhandled pattern type for match generation: #{inspect(pattern)}"
    end
  end

  # Helper to render a Lumata `Case` expression into AssemblyScript `if-else if` blocks.
  defp render_case(scrutinee, patterns) do
    # `valueToMatch` is a temporary variable to hold the scrutinee's value for matching.
    scrutinee_var = "valueToMatch"

    pattern_blocks =
      Enum.map(patterns, fn %Lumata.Ast.CasePattern{pattern: pat, guard: guard, expression: expr} ->
        {:ok, condition_str, binding_strs} =
          render_pattern_match_with_bindings(pat, scrutinee_var)

        guard_str = if guard, do: " && (#{render(guard)})", else: ""
        # Indent bindings correctly within the if block
        bindings_block =
          if Enum.empty?(binding_strs),
            do: "",
            else: "\n        " <> Enum.join(binding_strs, "\n        ") <> "\n"

        """
        if (#{condition_str}#{guard_str}) {#{bindings_block}
          return #{render(expr)};
        }
        """
      end)
      |> Enum.join(" else ")

    # Wrap the entire case expression in an IIFE (Immediately Invoked Function Expression)
    # to encapsulate scope and allow `return` statements for each branch.
    """
    ((#{scrutinee_var}: any) => {
      #{pattern_blocks} else {
        throw new Error("No match found for value: " + String(#{scrutinee_var}));
      }
    })(#{render(scrutinee)})
    """
  end

  # Helper to render a Lumata `Try` expression into AssemblyScript `try-catch` blocks.
  defp render_try(body, catch_patterns) do
    catch_blocks =
      Enum.map(catch_patterns, fn %Lumata.Ast.CatchPattern{pattern: pat, handler: handler_expr} ->
        # The caught error variable is conventionally `e` in AS/JS
        {:ok, condition_str, binding_strs} = render_pattern_match_with_bindings(pat, "e")

        bindings_block =
          if Enum.empty?(binding_strs),
            do: "",
            else: "\n          " <> Enum.join(binding_strs, "\n          ") <> "\n"

        """
        if (#{condition_str}) {#{bindings_block}
          return #{render(handler_expr)};
        }
        """
      end)
      |> Enum.join(" else ")

    # Wrap in IIFE for scope and return value.
    """
    ((_ => {
      try {
        return #{render(body)};
      } catch (e: any) { // Catch all errors, then pattern match
        #{catch_blocks} else {
          throw e; // Re-throw if no catch pattern matches
        }
      }
    })())
    """
  end
end
