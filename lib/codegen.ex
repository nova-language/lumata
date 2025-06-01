defmodule ElixirCodeGen do
  @moduledoc """
  Generates Elixir code from typed function definitions.
  """

  @doc """
  Generates Elixir module code from a list of typed function definitions.
  """
  def generate_module(module_name, typed_functions, type_ctx) do
    module_header = generate_module_header(module_name)
    type_definitions = generate_type_definitions(type_ctx)
    function_code = Enum.map(typed_functions, &generate_function/1)

    [module_header, "", type_definitions, "", Enum.join(function_code, "\n\n"), "end"]
    |> Enum.join("\n")
  end

  @doc """
  Generates Elixir code for a single typed function.
  """
  def generate_function(typed_func) do
    %{
      name: name,
      args: args,
      result_type: result_type,
      typed_body: body
    } = typed_func

    function_signature = generate_function_signature(name, args)
    function_body = generate_function_body(body)

    """
    #{function_signature} do
    #{indent(function_body, 2)}
    end
    """
  end

  # Private helper functions

  defp generate_module_header(module_name) do
    "defmodule #{module_name} do"
  end

  defp generate_type_definitions(type_ctx) do
    """
    # Type definitions would go here
    # Generated from TypeSystem context
    """
  end

  defp generate_function_signature(name, args) do
    elixir_name = to_snake_case(name)

    arg_list =
      Enum.map(args, fn %{"name" => arg_name} ->
        to_snake_case(arg_name)
      end)

    "def #{elixir_name}(#{Enum.join(arg_list, ", ")})"
  end

  defp generate_function_body(typed_body) do
    statements = Enum.map(typed_body, &generate_statement/1)
    Enum.join(statements, "\n")
  end

  defp generate_statement(%{identifier: "return", expr: expr}) do
    generate_expression(expr)
  end

  defp generate_statement(%{identifier: id, expr: expr}) do
    elixir_id = to_snake_case(id)
    elixir_expr = generate_expression(expr)
    "#{elixir_id} = #{elixir_expr}"
  end

  defp generate_expression(expr) when is_binary(expr) do
    # Convert string expressions to Elixir syntax
    expr
    |> String.replace("List.set", "List.replace_at")
    |> String.replace("List.get", "Enum.at")
    |> String.replace("List.length", "length")
    |> convert_array_access()
    |> convert_field_access()
  end

  defp generate_expression(%{"type" => "RecordCreation", "fields" => fields}) do
    field_assignments =
      Enum.map(fields, fn {key, value} ->
        "#{to_snake_case(key)}: #{generate_expression(value)}"
      end)

    "%{#{Enum.join(field_assignments, ", ")}}"
  end

  defp generate_expression(%{"type" => "RecordUpdate", "target" => target, "updates" => updates}) do
    update_assignments =
      Enum.map(updates, fn {key, value} ->
        "#{to_snake_case(key)}: #{generate_expression(value)}"
      end)

    "%{#{to_snake_case(target)} | #{Enum.join(update_assignments, ", ")}}"
  end

  defp generate_expression(%{"type" => "case", "on" => scrutinee, "patterns" => patterns}) do
    pattern_clauses =
      Enum.map(patterns, fn %{"pattern" => pattern, "expression" => expr} ->
        "  #{pattern} -> #{generate_expression(expr)}"
      end)

    """
    case #{to_snake_case(scrutinee)} do
    #{Enum.join(pattern_clauses, "\n")}
    end
    """
  end

  defp generate_expression(%{
         "type" => "map",
         "over" => collection,
         "iterator" => iterator,
         "expression" => map_expr
       }) do
    "Enum.map(#{generate_expression(collection)}, fn #{to_snake_case(iterator)} -> #{generate_expression(map_expr)} end)"
  end

  defp generate_expression(expr), do: inspect(expr)

  defp convert_array_access(expr) do
    # Convert cube.front[0] to Enum.at(cube.front, 0)
    Regex.replace(~r/(\w+)\.(\w+)\[(\d+)\]/, expr, "Enum.at(\\1.\\2, \\3)")
  end

  defp convert_field_access(expr) do
    # Convert cube.front to cube.front (no change needed in Elixir)
    expr
  end

  defp to_snake_case(str) do
    str
    |> String.replace(~r/([A-Z])/, "_\\1")
    |> String.downcase()
    |> String.trim_leading("_")
    |> String.replace("_prime", "_prime")
  end

  defp indent(text, spaces) do
    indent_str = String.duplicate(" ", spaces)

    text
    |> String.split("\n")
    |> Enum.map(&"#{indent_str}#{&1}")
    |> Enum.join("\n")
  end
end
