defmodule AssemblyScriptPrelude do
  @moduledoc """
  AssemblyScript type prelude containing all built-in types that correspond to WebAssembly types.

  AssemblyScript inherits WebAssembly's more specific integer, floating point and reference types.
  This module provides type definitions for all these types organized by category.
  """

  @doc """
  Returns all AssemblyScript built-in types as a type context map.
  """
  def types() do
    Map.merge(
      integer_types(),
      Map.merge(
        floating_point_types(),
        Map.merge(
          small_integer_types(),
          Map.merge(
            vector_types(),
            Map.merge(reference_types(), special_types())
          )
        )
      )
    )
  end

  @doc """
  32-bit and 64-bit integer types.
  """
  def integer_types() do
    %{
      "i32" => %{
        name: "i32",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "A 32-bit signed integer"
      },
      "u32" => %{
        name: "u32",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "A 32-bit unsigned integer"
      },
      "i64" => %{
        name: "i64",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i64",
        typescript_type: "bigint",
        description: "A 64-bit signed integer"
      },
      "u64" => %{
        name: "u64",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i64",
        typescript_type: "bigint",
        description: "A 64-bit unsigned integer"
      },
      "isize" => %{
        name: "isize",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32 or i64",
        typescript_type: "number or bigint",
        description: "A 32-bit signed integer in WASM32. A 64-bit signed integer in WASM64 🦄"
      },
      "usize" => %{
        name: "usize",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32 or i64",
        typescript_type: "number or bigint",
        description: "A 32-bit unsigned integer in WASM32. A 64-bit unsigned integer in WASM64 🦄"
      }
    }
  end

  @doc """
  Floating point types.
  """
  def floating_point_types() do
    %{
      "f32" => %{
        name: "f32",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "f32",
        typescript_type: "number",
        description: "A 32-bit float"
      },
      "f64" => %{
        name: "f64",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "f64",
        typescript_type: "number",
        description: "A 64-bit float"
      }
    }
  end

  @doc """
  Small integer types (8-bit and 16-bit).
  """
  def small_integer_types() do
    %{
      "i8" => %{
        name: "i8",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "An 8-bit signed integer"
      },
      "u8" => %{
        name: "u8",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "An 8-bit unsigned integer"
      },
      "i16" => %{
        name: "i16",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "A 16-bit signed integer"
      },
      "u16" => %{
        name: "u16",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "number",
        description: "A 16-bit unsigned integer"
      },
      "bool" => %{
        name: "bool",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "i32",
        typescript_type: "boolean",
        description: "A 1-bit unsigned integer"
      }
    }
  end

  @doc """
  Vector types.
  """
  def vector_types() do
    %{
      "v128" => %{
        name: "v128",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "v128",
        typescript_type: nil,
        description: "A 128-bit vector"
      }
    }
  end

  @doc """
  Reference and garbage collection types.
  """
  def reference_types() do
    %{
      "ref_extern" => %{
        name: "ref_extern",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref extern)",
        typescript_type: "Object",
        description: "An external reference"
      },
      "ref_func" => %{
        name: "ref_func",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref func)",
        typescript_type: "Function",
        description: "A function reference"
      },
      "ref_any" => %{
        name: "ref_any",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref any)",
        typescript_type: "Object",
        description: "An internal reference 🦄"
      },
      "ref_eq" => %{
        name: "ref_eq",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref eq)",
        typescript_type: "Object",
        description: "An equatable reference 🦄"
      },
      "ref_struct" => %{
        name: "ref_struct",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref struct)",
        typescript_type: "Object",
        description: "A data reference 🦄"
      },
      "ref_array" => %{
        name: "ref_array",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref array)",
        typescript_type: "Array",
        description: "An array reference 🦄"
      },
      "ref_string" => %{
        name: "ref_string",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref string)",
        typescript_type: "string",
        description: "A string reference 🦄"
      },
      "ref_stringview_wtf8" => %{
        name: "ref_stringview_wtf8",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref stringview_wtf8)",
        typescript_type: nil,
        description: "A WTF-8 string view reference 🦄"
      },
      "ref_stringview_wtf16" => %{
        name: "ref_stringview_wtf16",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref stringview_wtf16)",
        typescript_type: "string",
        description: "A WTF-16 string view reference 🦄"
      },
      "ref_stringview_iter" => %{
        name: "ref_stringview_iter",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: "(ref stringview_iter)",
        typescript_type: nil,
        description: "A string iterator reference 🦄"
      }
    }
  end

  @doc """
  Special types.
  """
  def special_types() do
    %{
      "void" => %{
        name: "void",
        type: "Primitive",
        namespace: "assemblyscript",
        wasm_type: nil,
        typescript_type: "void",
        description: "Indicates no return value"
      }
    }
  end

  @doc """
  Creates a TypeSystem context with AssemblyScript types preloaded.
  """
  def create_context() do
    ctx = TypeSystem.new()
    add_all_types(ctx, types())
  end

  @doc """
  Adds AssemblyScript types to an existing TypeSystem context.
  """
  def add_to_context(%TypeSystem{} = ctx) do
    add_all_types(ctx, types())
  end

  defp add_all_types(ctx, types_map) do
    Enum.reduce(types_map, ctx, fn {name, type_def}, acc_ctx ->
      case TypeSystem.add_type(acc_ctx, name, type_def) do
        {:ok, new_ctx} -> new_ctx
        # Skip types that fail validation
        {:error, _reason} -> acc_ctx
      end
    end)
  end

  @doc """
  Gets types by category.
  """
  def get_types_by_category(category) do
    case category do
      :integer -> integer_types()
      :floating_point -> floating_point_types()
      :small_integer -> small_integer_types()
      :vector -> vector_types()
      :reference -> reference_types()
      :special -> special_types()
      :all -> types()
      _ -> %{}
    end
  end

  @doc """
  Lists all available type categories.
  """
  def categories() do
    [:integer, :floating_point, :small_integer, :vector, :reference, :special]
  end

  @doc """
  Gets type information including WebAssembly and TypeScript mappings.
  """
  def type_info(type_name) when is_binary(type_name) do
    Map.get(types(), type_name)
  end

  @doc """
  Checks if a type is an AssemblyScript built-in type.
  """
  def assemblyscript_type?(type_name) when is_binary(type_name) do
    Map.has_key?(types(), type_name)
  end

  @doc """
  Gets all type names grouped by category.
  """
  def type_names_by_category() do
    %{
      integer: Map.keys(integer_types()),
      floating_point: Map.keys(floating_point_types()),
      small_integer: Map.keys(small_integer_types()),
      vector: Map.keys(vector_types()),
      reference: Map.keys(reference_types()),
      special: Map.keys(special_types())
    }
  end
end

# Usage example
defmodule AssemblyScriptPreludeExample do
  @doc """
  Example usage of the AssemblyScript prelude.
  """
  def run_examples() do
    # Create a context with AssemblyScript types
    ctx = AssemblyScriptPrelude.create_context()

    # Check if AssemblyScript types exist
    IO.puts("i32 exists: #{TypeSystem.type_exists?(ctx, "i32")}")
    IO.puts("f64 exists: #{TypeSystem.type_exists?(ctx, "f64")}")
    IO.puts("ref_string exists: #{TypeSystem.type_exists?(ctx, "ref_string")}")

    # Get type information
    i32_info = AssemblyScriptPrelude.type_info("i32")
    IO.inspect(i32_info, label: "i32 type info")

    f64_info = AssemblyScriptPrelude.type_info("f64")
    IO.inspect(f64_info, label: "f64 type info")

    # List types by category
    integer_types = AssemblyScriptPrelude.get_types_by_category(:integer)
    IO.inspect(Map.keys(integer_types), label: "Integer types")

    reference_types = AssemblyScriptPrelude.get_types_by_category(:reference)
    IO.inspect(Map.keys(reference_types), label: "Reference types")

    # Get all categories
    IO.inspect(AssemblyScriptPrelude.categories(), label: "All categories")

    # Check if a type is AssemblyScript built-in
    IO.puts("i64 is AssemblyScript type: #{AssemblyScriptPrelude.assemblyscript_type?("i64")}")

    IO.puts(
      "String is AssemblyScript type: #{AssemblyScriptPrelude.assemblyscript_type?("String")}"
    )

    # Get type names organized by category
    categorized_names = AssemblyScriptPrelude.type_names_by_category()
    IO.inspect(categorized_names, label: "Type names by category")

    # Add to existing context
    basic_ctx = TypeSystem.new()
    enhanced_ctx = AssemblyScriptPrelude.add_to_context(basic_ctx)

    all_types = TypeSystem.all_type_names(enhanced_ctx)
    IO.inspect(all_types, label: "All types in enhanced context")
  end
end
