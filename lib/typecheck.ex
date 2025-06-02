defmodule TypeChecker do
  @moduledoc """
  outdated 
  """

  alias TypeSystem

  @type typing_context :: %{String.t() => String.t() | TypeSystem.parsed_type()}

  @type expression :: %{
          type: String.t()
        }

  @type function_def :: %{
          name: String.t(),
          args: [%{name: String.t(), type: String.t()}],
          result_type: String.t(),
          body_structure: [
            %{
              identifier: String.t(),
              type: String.t(),
              expr: expression() | String.t()
            }
          ]
        }

  @doc """
  Type checks a function definition against a type system context.
  """
  def typecheck_function(%TypeSystem{} = type_ctx, func_def) do
    %{
      "name" => name,
      "args" => args,
      "result_type" => result_type,
      "body_structure" => body
    } = func_def

    with :ok <- validate_function_signature(type_ctx, name, args, result_type),
         {:ok, local_ctx} <- build_local_context(type_ctx, args),
         {:ok, typed_body} <- typecheck_body(type_ctx, local_ctx, body, result_type) do
      {:ok,
       %{
         name: name,
         args: args,
         result_type: result_type,
         typed_body: typed_body
       }}
    end
  end

  @doc """
  Type checks an expression within a given context.
  """
  def typecheck_expression(type_ctx, local_ctx, expr) do
    case expr do
      # String literals for simple expressions
      expr_str when is_binary(expr_str) ->
        parse_and_type_expression(type_ctx, local_ctx, expr_str)

      # Structured expressions
      %{"type" => "RecordCreation", "fields" => fields} ->
        typecheck_record_creation(type_ctx, local_ctx, fields)

      %{"type" => "RecordUpdate", "target" => target, "updates" => updates} ->
        typecheck_record_update(type_ctx, local_ctx, target, updates)

      %{"type" => "case", "on" => scrutinee, "patterns" => patterns} ->
        typecheck_case_expression(type_ctx, local_ctx, scrutinee, patterns)

      %{"type" => "map", "over" => collection, "iterator" => iter, "expression" => map_expr} ->
        typecheck_map_expression(type_ctx, local_ctx, collection, iter, map_expr)

      _ ->
        {:error, "Unknown expression type: #{inspect(expr)}"}
    end
  end

  # Private helper functions

  defp validate_function_signature(type_ctx, name, args, result_type) do
    with :ok <- validate_type_exists(type_ctx, result_type),
         :ok <- validate_args_types(type_ctx, args) do
      :ok
    end
  end

  defp validate_type_exists(type_ctx, type_name) do
    if TypeSystem.type_exists?(type_ctx, type_name) do
      :ok
    else
      {:error, "Unknown type: #{type_name}"}
    end
  end

  defp validate_args_types(type_ctx, args) do
    Enum.reduce_while(args, :ok, fn %{"type" => type}, :ok ->
      case validate_type_exists(type_ctx, type) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp build_local_context(type_ctx, args) do
    local_vars =
      Enum.reduce(args, %{}, fn %{"name" => name, "type" => type}, acc ->
        Map.put(acc, name, type)
      end)

    {:ok, local_vars}
  end

  defp typecheck_body(type_ctx, local_ctx, body, expected_return_type) do
    {typed_statements, final_ctx} =
      Enum.reduce(body, {[], local_ctx}, fn stmt, {acc_stmts, ctx} ->
        case typecheck_statement(type_ctx, ctx, stmt) do
          {:ok, typed_stmt, new_ctx} ->
            {[typed_stmt | acc_stmts], new_ctx}

          {:error, _} = error ->
            throw(error)
        end
      end)

    # Verify the last statement returns the expected type
    case List.first(IO.inspect(typed_statements)) do
      %{identifier: "return", inferred_type: return_type} ->
        if types_compatible?(return_type, expected_return_type) do
          {:ok, Enum.reverse(typed_statements)}
        else
          {:error, "Return type mismatch. Expected: #{expected_return_type}, got: #{return_type}"}
        end

      _ ->
        {:error, "Function must end with a return statement"}
    end
  catch
    {:error, _} = error -> error
  end

  defp typecheck_statement(type_ctx, local_ctx, stmt) do
    %{
      "identifier" => id,
      "type" => declared_type,
      "expr" => expr
    } = stmt

    case typecheck_expression(type_ctx, local_ctx, expr) do
      {:ok, inferred_type} ->
        if types_compatible?(inferred_type, declared_type) do
          new_ctx = Map.put(local_ctx, id, inferred_type)

          typed_stmt = %{
            identifier: id,
            declared_type: declared_type,
            inferred_type: inferred_type,
            expr: expr
          }

          {:ok, typed_stmt, new_ctx}
        else
          {:error,
           "Type mismatch for #{id}. Declared: #{declared_type}, inferred: #{inferred_type}"}
        end

      {:error, _} = error ->
        error
    end
  end

  defp typecheck_record_creation(type_ctx, local_ctx, fields) do
    # For now, assume CubeState record creation
    # In a full implementation, we'd look up the record type definition
    {:ok, "CubeState"}
  end

  defp typecheck_record_update(type_ctx, local_ctx, target, updates) do
    case Map.get(local_ctx, target) do
      nil -> {:error, "Unknown variable: #{target}"}
      target_type -> {:ok, target_type}
    end
  end

  defp typecheck_case_expression(type_ctx, local_ctx, scrutinee, patterns) do
    case Map.get(local_ctx, scrutinee) do
      nil ->
        {:error, "Unknown variable in case expression: #{scrutinee}"}

      scrutinee_type ->
        # All patterns should return the same type
        pattern_types =
          Enum.map(patterns, fn %{"expression" => expr} ->
            case typecheck_expression(type_ctx, local_ctx, expr) do
              {:ok, type} -> type
              _ -> nil
            end
          end)

        case Enum.uniq(pattern_types) do
          [single_type] when single_type != nil -> {:ok, single_type}
          _ -> {:error, "Case expression branches have inconsistent types"}
        end
    end
  end

  defp typecheck_map_expression(type_ctx, local_ctx, collection, iterator, map_expr) do
    # Simplified: assume List operations
    {:ok, "List{Color}"}
  end

  defp parse_and_type_expression(type_ctx, local_ctx, expr_str) do
    cond do
      # Variable reference
      Map.has_key?(local_ctx, expr_str) ->
        {:ok, Map.get(local_ctx, expr_str)}

      # Function call pattern (simplified)
      String.contains?(expr_str, "(") ->
        infer_function_call_type(type_ctx, local_ctx, expr_str)

      # List literal
      String.starts_with?(expr_str, "[") ->
        # Simplified
        {:ok, "List{Color}"}

      # Field access
      String.contains?(expr_str, ".") ->
        infer_field_access_type(type_ctx, local_ctx, expr_str)

      true ->
        {:error, "Cannot infer type for expression: #{expr_str}"}
    end
  end

  defp infer_function_call_type(type_ctx, local_ctx, expr_str) do
    # Simplified function call type inference
    cond do
      String.contains?(expr_str, "performUMove") -> {:ok, "CubeState"}
      String.contains?(expr_str, "rotateClockwise") -> {:ok, "List{List{Color}}"}
      String.contains?(expr_str, "List.set") -> {:ok, "List{List{Color}}"}
      String.contains?(expr_str, "List.length") -> {:ok, "Number"}
      # In practice, we'd have a function registry
      true -> {:ok, "Unknown"}
    end
  end

  defp infer_field_access_type(type_ctx, local_ctx, expr_str) do
    case String.split(expr_str, ".") do
      [var, field] ->
        case Map.get(local_ctx, var) do
          "CubeState" ->
            if field in ["front", "back", "up", "down", "left", "right"] do
              {:ok, "List{List{Color}}"}
            else
              {:error, "Unknown field #{field} for CubeState"}
            end

          _ ->
            {:error, "Cannot access field #{field} on variable #{var}"}
        end

      [var, field, index] ->
        # Array access like cube.front[0]
        {:ok, "List{Color}"}

      _ ->
        {:error, "Invalid field access: #{expr_str}"}
    end
  end

  defp types_compatible?(type1, type2) do
    # Simplified compatibility check
    type1 == type2
  end
end

# Example usage and testing
defmodule TypeCheckerExample do
  def run_example() do
    # Create type context with Rubik's cube types
    cube_types = TypeSystemExample.rubiks_cube_types()
    type_ctx = TypeSystem.new()

    # Example function definition (from your JSON structure)
    init_cube_func = %{
      "name" => "initializeCube",
      "args" => [],
      "result_type" => "CubeState",
      "body_structure" => [
        %{
          "identifier" => "initialState",
          "type" => "CubeState",
          "expr" => %{
            "type" => "RecordCreation",
            "fields" => %{
              "front" => "[ [Red,Red,Red], [Red,Red,Red], [Red,Red,Red] ]",
              "back" =>
                "[ [Orange,Orange,Orange], [Orange,Orange,Orange], [Orange,Orange,Orange] ]",
              "up" => "[ [White,White,White], [White,White,White], [White,White,White] ]",
              "down" =>
                "[ [Yellow,Yellow,Yellow], [Yellow,Yellow,Yellow], [Yellow,Yellow,Yellow] ]",
              "left" => "[ [Green,Green,Green], [Green,Green,Green], [Green,Green,Green] ]",
              "right" => "[ [Blue,Blue,Blue], [Blue,Blue,Blue], [Blue,Blue,Blue] ]"
            }
          }
        },
        %{
          "identifier" => "return",
          "type" => "CubeState",
          "expr" => "initialState"
        }
      ]
    }

    # Type check the function
    case TypeChecker.typecheck_function(type_ctx, init_cube_func) do
      {:ok, typed_func} ->
        IO.puts("✓ Type checking passed!")
        IO.inspect(typed_func, label: "Typed function")

        # Generate Elixir code
        elixir_code = ElixirCodeGen.generate_function(typed_func)
        IO.puts("\n Generated Elixir code:")
        IO.puts(elixir_code)

      {:error, msg} ->
        IO.puts("✗ Type checking failed: #{msg}")
    end
  end
end
