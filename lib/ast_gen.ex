defmodule Lumata.Ast.Generator do
  alias TypeSystem

  @namespace "Lumata.Ast"

  @doc """
  Generates Elixir AST module definitions from the TypeSystem context.
  Returns a list of strings, each representing a module.
  """
  def generate_ast_modules(ctx) do
    # Get all user-defined types in the Lumata.Ast namespace
    ast_type_defs =
      ctx.user_types
      |> Map.values()
      |> Enum.filter(fn %{namespace: ns} -> ns == @namespace end)

    # Filter for Record types, as these become defstructs
    record_types =
      Enum.filter(ast_type_defs, fn %{type: type} -> type == "Record" end)

    # Generate module strings for each record type
    record_modules =
      Enum.map(record_types, fn type_def ->
        generate_record_module(type_def)
      end)

    # Generate the main Lumata.Ast dispatcher module
    dispatcher_module = generate_dispatcher_module(ast_type_defs)

    record_modules ++ [dispatcher_module]
  end

  defp generate_record_module(type_def) do
    module_name = type_def.name
    full_module_name = "Lumata.Ast.#{module_name}"
    fields = type_def.fields

    struct_fields =
      fields
      |> Enum.map(fn {field_name, _field_type} ->
        # All fields default to nil for defstruct
        "#{field_name}: nil"
      end)
      |> Enum.join(", ")

    # Generate from_js_map and to_js_map
    from_js_map_body = generate_from_js_map_body(fields)
    to_js_map_body = generate_to_js_map_body(fields)

    """
    defmodule #{full_module_name} do
      @moduledoc \"\"\"
      Represents the `#{module_name}` AST node.
      \"\"\"
      defstruct #{struct_fields}

      @doc \"\"\"
      Converts a map (e.g., from JSON/JS) into a `#{full_module_name}` struct.
      \"\"\"
      def from_js_map(data) do
        %__MODULE__{
    #{from_js_map_body}
        }
      end

      @doc \"\"\"
      Converts a `#{full_module_name}` struct into a map for serialization (e.g., to JSON/JS).
      \"\"\"
      def to_js_map(%__MODULE__{} = struct) do
        Map.merge(
          %{kind: "#{module_name}"},
          %{
    #{to_js_map_body}
          }
        )
      end
    end
    """
  end

  defp generate_from_js_map_body(fields) do
    fields
    |> Enum.map(fn {field_name, field_type} ->
      conversion_code = generate_field_from_js_map_conversion(field_name, field_type)
      "          #{field_name}: #{conversion_code}"
    end)
    |> Enum.join(",\n")
  end

  defp generate_to_js_map_body(fields) do
    fields
    |> Enum.map(fn {field_name, field_type} ->
      conversion_code = generate_field_to_js_map_conversion(field_name, field_type)
      "          \"#{field_name}\" => #{conversion_code}" # Use string keys for JS map output
    end)
    |> Enum.join(",\n")
  end

  # Helper for from_js_map field conversion
  defp generate_field_from_js_map_conversion(field_name, field_type) do
    case field_type do
      # Simple types (String, Int, Bool, Number, Unit)
      "String" -> "Map.get(data, \"#{field_name}\")"
      "Int" -> "Map.get(data, \"#{field_name}\")"
      "Bool" -> "Map.get(data, \"#{field_name}\")"
      "Number" -> "Map.get(data, \"#{field_name}\")"
      "Unit" -> "Map.get(data, \"#{field_name}\")"

      # AST union types (treated as "Primitive" placeholders that are actually sum types of records)
      # Or other specific AST Records that are not unions (e.g., QualifiedIdentifier)
      type_name when is_binary(type_name) ->
        "Lumata.Ast.from_js_map(Map.get(data, \"#{field_name}\"))"

      # Parameterized types
      %{constructor: "List", vars: [var_type]} ->
        list_element_conversion = generate_list_element_from_js_map_conversion(var_type)
        "Enum.map(Map.get(data, \"#{field_name}\", []), fn elem -> #{list_element_conversion} end)"

      %{constructor: "Map", vars: [key_type, val_type]} ->
        # Assuming K is String for now based on AST definitions
        map_key_conversion = generate_map_key_from_js_map_conversion(key_type)
        map_value_conversion = generate_map_value_from_js_map_conversion(val_type)
        """
        Map.new(Map.get(data, \"#{field_name}\", []), fn {k, v} ->
            {#{map_key_conversion}, #{map_value_conversion}}
          end)
        """

      %{constructor: "Maybe", vars: [var_type]} ->
        maybe_conversion = generate_maybe_from_js_map_conversion(var_type)
        """
        case Map.get(data, \"#{field_name}\") do
            nil -> nil
            value -> #{maybe_conversion}
          end
        """

      _ ->
        # Fallback for any unhandled complex types, or error for unexpected types
        "Map.get(data, \"#{field_name}\") # WARNING: UNHANDLED TYPE #{inspect(field_type)}"
    end
  end

  # Helper for to_js_map field conversion
  defp generate_field_to_js_map_conversion(field_name, field_type) do
    case field_type do
      # Simple types (String, Int, Bool, Number, Unit)
      "String" -> "struct.#{field_name}"
      "Int" -> "struct.#{field_name}"
      "Bool" -> "struct.#{field_name}"
      "Number" -> "struct.#{field_name}"
      "Unit" -> "struct.#{field_name}"

      # AST union types or other specific AST Records
      type_name when is_binary(type_name) ->
        "Lumata.Ast.to_js_map(struct.#{field_name})"

      # Parameterized types
      %{constructor: "List", vars: [var_type]} ->
        list_element_conversion = generate_list_element_to_js_map_conversion(var_type)
        "Enum.map(struct.#{field_name}, fn elem -> #{list_element_conversion} end)"

      %{constructor: "Map", vars: [key_type, val_type]} ->
        map_key_conversion = generate_map_key_to_js_map_conversion(key_type)
        map_value_conversion = generate_map_value_to_js_map_conversion(val_type)
        """
        Map.new(struct.#{field_name}, fn {k, v} ->
            {#{map_key_conversion}, #{map_value_conversion}}
          end)
        """

      %{constructor: "Maybe", vars: [var_type]} ->
        maybe_conversion = generate_maybe_to_js_map_conversion(var_type)
        """
        if struct.#{field_name} do
            #{maybe_conversion}
          else
            nil
          end
        """

      _ ->
        "struct.#{field_name} # WARNING: UNHANDLED TYPE #{inspect(field_type)}"
    end
  end

  # --- Nested type conversion helpers (from_js_map) ---
  defp generate_list_element_from_js_map_conversion(element_type) do
    case element_type do
      "String" -> "elem"
      "Int" -> "elem"
      "Bool" -> "elem"
      "Number" -> "elem"
      "Unit" -> "elem"
      type_name when is_binary(type_name) -> "Lumata.Ast.from_js_map(elem)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_from_js_map_conversion(inner_type)
        "Enum.map(elem, fn inner_elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_from_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_from_js_map_conversion(inner_val_type)
        "Map.new(elem, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_from_js_map_conversion(inner_type)
        "if elem, do: #{inner_conversion}, else: nil"
      _ -> "elem # WARNING: UNHANDLED LIST ELEMENT TYPE #{inspect(element_type)}"
    end
  end

  defp generate_map_key_from_js_map_conversion(key_type) do
    case key_type do
      "String" -> "k" # Assuming string keys in JS map to string keys in Elixir map
      _ -> "k # WARNING: UNHANDLED MAP KEY TYPE #{inspect(key_type)}"
    end
  end

  defp generate_map_value_from_js_map_conversion(value_type) do
    case value_type do
      "String" -> "v"
      "Int" -> "v"
      "Bool" -> "v"
      "Number" -> "v"
      "Unit" -> "v"
      type_name when is_binary(type_name) -> "Lumata.Ast.from_js_map(v)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_from_js_map_conversion(inner_type)
        "Enum.map(v, fn elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_from_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_from_js_map_conversion(inner_val_type)
        "Map.new(v, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_from_js_map_conversion(inner_type)
        "if v, do: #{inner_conversion}, else: nil"
      _ -> "v # WARNING: UNHANDLED MAP VALUE TYPE #{inspect(value_type)}"
    end
  end

  defp generate_maybe_from_js_map_conversion(maybe_type) do
    case maybe_type do
      "String" -> "value"
      "Int" -> "value"
      "Bool" -> "value"
      "Number" -> "value"
      "Unit" -> "value"
      type_name when is_binary(type_name) -> "Lumata.Ast.from_js_map(value)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_from_js_map_conversion(inner_type)
        "Enum.map(value, fn elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_from_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_from_js_map_conversion(inner_val_type)
        "Map.new(value, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_from_js_map_conversion(inner_type)
        "if value, do: #{inner_conversion}, else: nil"
      _ -> "value # WARNING: UNHANDLED MAYBE TYPE #{inspect(maybe_type)}"
    end
  end

  # --- Nested type conversion helpers (to_js_map) ---
  defp generate_list_element_to_js_map_conversion(element_type) do
    case element_type do
      "String" -> "elem"
      "Int" -> "elem"
      "Bool" -> "elem"
      "Number" -> "elem"
      "Unit" -> "elem"
      type_name when is_binary(type_name) -> "Lumata.Ast.to_js_map(elem)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_to_js_map_conversion(inner_type)
        "Enum.map(elem, fn inner_elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_to_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_to_js_map_conversion(inner_val_type)
        "Map.new(elem, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_to_js_map_conversion(inner_type)
        "if elem, do: #{inner_conversion}, else: nil"
      _ -> "elem # WARNING: UNHANDLED LIST ELEMENT TYPE #{inspect(element_type)}"
    end
  end

  defp generate_map_key_to_js_map_conversion(key_type) do
    case key_type do
      "String" -> "k"
      _ -> "k # WARNING: UNHANDLED MAP KEY TYPE #{inspect(key_type)}"
    end
  end

  defp generate_map_value_to_js_map_conversion(value_type) do
    case value_type do
      "String" -> "v"
      "Int" -> "v"
      "Bool" -> "v"
      "Number" -> "v"
      "Unit" -> "v"
      type_name when is_binary(type_name) -> "Lumata.Ast.to_js_map(v)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_to_js_map_conversion(inner_type)
        "Enum.map(v, fn elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_to_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_to_js_map_conversion(inner_val_type)
        "Map.new(v, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_to_js_map_conversion(inner_type)
        "if v, do: #{inner_conversion}, else: nil"
      _ -> "v # WARNING: UNHANDLED MAP VALUE TYPE #{inspect(value_type)}"
    end
  end

  defp generate_maybe_to_js_map_conversion(maybe_type) do
    case maybe_type do
      "String" -> "value"
      "Int" -> "value"
      "Bool" -> "value"
      "Number" -> "value"
      "Unit" -> "value"
      type_name when is_binary(type_name) -> "Lumata.Ast.to_js_map(value)"
      %{constructor: "List", vars: [inner_type]} ->
        inner_conversion = generate_list_element_to_js_map_conversion(inner_type)
        "Enum.map(value, fn elem -> #{inner_conversion} end)"
      %{constructor: "Map", vars: [inner_key_type, inner_val_type]} ->
        inner_key_conversion = generate_map_key_to_js_map_conversion(inner_key_type)
        inner_val_conversion = generate_map_value_to_js_map_conversion(inner_val_type)
        "Map.new(value, fn {k, v} -> {#{inner_key_conversion}, #{inner_val_conversion}} end)"
      %{constructor: "Maybe", vars: [inner_type]} ->
        inner_conversion = generate_maybe_to_js_map_conversion(inner_type)
        "if value, do: #{inner_conversion}, else: nil"
      _ -> "value # WARNING: UNHANDLED MAYBE TYPE #{inspect(maybe_type)}"
    end
  end


  # Generate the central dispatcher module (Lumata.Ast)
  defp generate_dispatcher_module(ast_type_defs) do
    # Mapping from union type name to its concrete record types.
    # This is inferred from the Lumata.Ast.Types definitions and the structure of the AST.
    # The "Primitive" types like Expression, Pattern, etc., act as sum types.
    union_members = %{
      "Expression" => [
        "IntLiteral", "StringLiteral", "BoolLiteral", "ListLiteral", "RecordLiteral",
        "Variable", "FunctionCall", "FieldAccess", "ListAccess", "BinaryOp", "UnaryOp",
        "RecordCreation", "RecordUpdate", "ConstructorCall", "Case", "If", "Let", "Lambda",
        "Map", "Filter", "Fold", "Try", "Do", "TypeAnnotation"
      ],
      "Pattern" => [
        "WildcardPattern", "VariablePattern", "LiteralPattern", "ConstructorPattern",
        "RecordPattern", "ListPattern", "AsPattern", "OrPattern"
      ],
      "LiteralValue" => [
        "IntLiteral", "StringLiteral", "BoolLiteral", "ListLiteral", "RecordLiteral"
      ],
      "CasePattern" => ["CasePattern"], # CasePattern is a record itself, and also the only member of the CasePattern union.
      "DoStatement" => ["Bind", "ExpressionStatement"]
    }

    # Generate `from_js_map` clauses for dispatching based on "kind" field
    from_js_map_clauses =
      Enum.flat_map(union_members, fn {_union_name, members} ->
        Enum.map(members, fn type_name ->
          "      def from_js_map(%{\"kind\" => \"#{type_name}\"} = data), do: Lumata.Ast.#{type_name}.from_js_map(data)"
        end)
      end)
      |> Enum.join("\n")

    # Add a catch-all for `from_js_map` for primitive values that don't have a "kind"
    from_js_map_clauses = from_js_map_clauses <> "\n      def from_js_map(data), do: data # Fallback for primitive types (Int, String, Bool, etc.)"

    # Generate `to_js_map` clauses for all record types
    to_js_map_clauses =
      ast_type_defs
      |> Enum.filter(fn %{type: "Record"} -> true; _ -> false end)
      |> Enum.map(fn type_def ->
        module_name = type_def.name
        "      def to_js_map(%Lumata.Ast.#{module_name}{} = struct), do: Lumata.Ast.#{module_name}.to_js_map(struct)"
      end)
      |> Enum.join("\n")

    # Add a catch-all for `to_js_map` for primitive values
    to_js_map_clauses = to_js_map_clauses <> "\n      def to_js_map(value), do: value # Fallback for primitive types (Int, String, Bool, etc.)"

    """
    defmodule Lumata.Ast do
      @moduledoc \"\"\"
      Central module for Lumata AST node conversion.
      Handles dispatching `from_js_map` and `to_js_map` for union types.
      \"\"\"

      @doc \"\"\"
      Converts a generic map (e.g., from JSON/JS) into the appropriate Lumata AST struct.
      Dispatches based on the `kind` field for complex types.
      \"\"\"
    #{from_js_map_clauses}

      @doc \"\"\"
      Converts a Lumata AST struct into a generic map for serialization (e.g., to JSON/JS).
      Dispatches based on the struct type.
      \"\"\"
    #{to_js_map_clauses}
    end
    """
  end

  def test do
# 1. Initialize TypeSystem context
ctx = TypeSystem.new()

# 2. Add Lumata AST type definitions to the context
#    (This part is from your original Lumata.Ast.Types module)
ctx = Lumata.Ast.Types.add_ast_types(ctx)

# 3. Generate the Elixir module code
generated_modules = Lumata.Ast.Generator.generate_ast_modules(ctx)

# 4. Print the generated code (in a real project, you'd write this to files)
Enum.each(generated_modules, fn module_code ->
  IO.puts "--- Generated Module ---"
  IO.puts module_code
  # In a real application, you might write this to a file:
  # File.write!("path/to/your/generated/module.ex", module_code)
  # Or compile it directly:
  # Code.compile_string(module_code)
end)
end
end


