defmodule TypeSystem do
  @moduledoc """
  A type system context for representing and working with algebraic data types.
  Supports primitives, parameterized types, sum types (Data), and product types (Record).
  Also supports foreign function imports and user-defined functions.
  """

  @built_in_types %{
    "List" => %{
      name: "List",
      type: "Parameterized",
      parameters: ["a"],
      namespace: "builtin"
    },
    "String" => %{
      name: "String",
      type: "Primitive",
      namespace: "builtin"
    },
    "Int" => %{
      name: "Int",
      type: "Primitive",
      namespace: "builtin"
    },
    # Kept as distinct from Int for broader numeric types
    "Number" => %{
      name: "Number",
      type: "Primitive",
      namespace: "builtin"
    },
    "Bool" => %{
      name: "Bool",
      type: "Sum",
      constructors: ["True", "False"],
      namespace: "builtin"
    },
    # Added for AST type definitions
    "Map" => %{
      name: "Map",
      type: "Parameterized",
      parameters: ["K", "V"],
      namespace: "builtin"
    },
    "Maybe" => %{
      name: "Maybe",
      type: "Sum",
      constructors: [%{name: "Some", vars: ["a"]}, "None"],
      parameters: ["a"],
      namespace: "builtin"
    },
    # Represents 'nil' or void, if explicitly typed
    "Unit" => %{
      name: "Unit",
      type: "Primitive",
      namespace: "builtin"
    }
  }

  @type parsed_type ::
          %{
            constructor: String.t(),
            vars: [parsed_type() | String.t()]
          }
          | String.t()

  @type type_def :: %{
          name: String.t(),
          constructors: [String.t()] | nil,
          type: String.t() | nil,
          # Changed fields to map for clarity
          fields: %{String.t() => String.t() | parsed_type()} | nil,
          namespace: String.t() | nil
        }

  @type foreign_import :: %{
          name: String.t(),
          namespace: String.t(),
          ffi_name: String.t(),
          ffi_module: String.t(),
          arity: non_neg_integer(),
          arg_types: [String.t()],
          return_type: String.t()
        }

  @type function_def :: %{
          name: String.t(),
          namespace: String.t(),
          metadata: map()
        }

  @type type_context :: %{String.t() => type_def()}
  @type foreign_import_context :: %{String.t() => foreign_import()}
  @type function_context :: %{String.t() => function_def()}

  defstruct [:user_types, :built_ins, :foreign_imports, :functions]

  @type t :: %__MODULE__{
          user_types: type_context(),
          built_ins: type_context(),
          foreign_imports: foreign_import_context(),
          functions: function_context()
        }

  @doc """
  Creates a new type system context with built-in types only.
  User-defined types must be added and validated individually.
  """
  def new() do
    %__MODULE__{
      user_types: %{},
      built_ins: @built_in_types,
      foreign_imports: %{},
      functions: %{}
    }
  end

  @doc """
  Adds a type definition to the context after validation.
  """
  def add_type(%__MODULE__{} = ctx, name, type_def) when is_binary(name) do
    with :ok <- validate_type_definition(ctx, type_def) do
      {:ok, %{ctx | user_types: Map.put(ctx.user_types, name, type_def)}}
    end
  end

  @doc """
  Adds a foreign function import to the context.

  ## Example
      TypeSystem.add_foreign_import(ctx, "sqrt", "Math", %{
        ffi_name: "sqrt",
        ffi_module: "Math",
        arity: 1,
        arg_types: ["Number"],
        return_type: "Number"
      })
  """
  def add_foreign_import(%__MODULE__{} = ctx, name, namespace, metadata)
      when is_binary(name) and is_binary(namespace) and is_map(metadata) do
    with :ok <- validate_foreign_import_metadata(ctx, metadata) do
      import_def = %{
        name: name,
        namespace: namespace,
        ffi_name: Map.get(metadata, :ffi_name) || Map.get(metadata, "ffi_name"),
        ffi_module: Map.get(metadata, :ffi_module) || Map.get(metadata, "ffi_module"),
        arity: Map.get(metadata, :arity) || Map.get(metadata, "arity"),
        arg_types: Map.get(metadata, :arg_types) || Map.get(metadata, "arg_types", []),
        return_type: Map.get(metadata, :return_type) || Map.get(metadata, "return_type")
      }

      key = "#{namespace}.#{name}"
      {:ok, %{ctx | foreign_imports: Map.put(ctx.foreign_imports, key, import_def)}}
    end
  end

  @doc """
  Adds a user-defined function to the context.

  ## Example
      TypeSystem.add_function(ctx, "factorial", "MyModule", %{
        arg_types: ["Int"],
        return_type: "Int",
        pure: true
      })
  """
  def add_function(%__MODULE__{} = ctx, name, namespace, metadata)
      when is_binary(name) and is_binary(namespace) and is_map(metadata) do
    with :ok <- validate_function_metadata(ctx, metadata) do
      function_def = %{
        name: name,
        namespace: namespace,
        metadata: metadata
      }

      key = "#{namespace}.#{name}"
      {:ok, %{ctx | functions: Map.put(ctx.functions, key, function_def)}}
    end
  end

  @doc """
  Looks up a type by name, checking user types first, then built-ins.
  """
  def lookup_type(%__MODULE__{} = ctx, name) when is_binary(name) do
    case Map.get(ctx.user_types, name) do
      nil -> Map.get(ctx.built_ins, name)
      type -> type
    end
  end

  @doc """
  Looks up a foreign import by qualified name (namespace.name).
  """
  def lookup_foreign_import(%__MODULE__{} = ctx, qualified_name) when is_binary(qualified_name) do
    Map.get(ctx.foreign_imports, qualified_name)
  end

  @doc """
  Looks up a function by qualified name (namespace.name).
  """
  def lookup_function(%__MODULE__{} = ctx, qualified_name) when is_binary(qualified_name) do
    Map.get(ctx.functions, qualified_name)
  end

  @doc """
  Checks if a type exists in the context.
  """
  def type_exists?(%__MODULE__{} = ctx, name) when is_binary(name) do
    Map.has_key?(ctx.user_types, name) or Map.has_key?(ctx.built_ins, name)
  end

  @doc """
  Checks if a foreign import exists in the context.
  """
  def foreign_import_exists?(%__MODULE__{} = ctx, qualified_name)
      when is_binary(qualified_name) do
    Map.has_key?(ctx.foreign_imports, qualified_name)
  end

  @doc """
  Checks if a function exists in the context.
  """
  def function_exists?(%__MODULE__{} = ctx, qualified_name) when is_binary(qualified_name) do
    Map.has_key?(ctx.functions, qualified_name)
  end

  @doc """
  Gets all type names available in the context.
  """
  def all_type_names(%__MODULE__{} = ctx) do
    Map.keys(ctx.user_types) ++ Map.keys(ctx.built_ins)
  end

  @doc """
  Gets all foreign import names available in the context.
  """
  def all_foreign_import_names(%__MODULE__{} = ctx) do
    Map.keys(ctx.foreign_imports)
  end

  @doc """
  Gets all function names available in the context.
  """
  def all_function_names(%__MODULE__{} = ctx) do
    Map.keys(ctx.functions)
  end

  @doc """
  Validates a parsed type against the context.
  """
  def validate_type(%__MODULE__{} = ctx, type) do
    case type do
      name when is_binary(name) ->
        if type_exists?(ctx, name) do
          :ok
        else
          {:error, "Unknown type: #{name}"}
        end

      %{constructor: constructor, vars: vars} ->
        with :ok <- validate_constructor(ctx, constructor),
             :ok <- validate_type_vars(ctx, vars) do
          :ok
        end

      _ ->
        {:error, "Invalid type format"}
    end
  end

  defp validate_type_definition(ctx, type_def) do
    case type_def do
      %{type: "Data", constructors: constructors} when is_list(constructors) ->
        :ok

      %{type: "Record", fields: fields} when is_map(fields) ->
        validate_record_fields(ctx, fields)

      %{type: "Primitive"} ->
        :ok

      %{type: "Parameterized", parameters: params} when is_list(params) ->
        :ok

      _ ->
        {:error, "Invalid type definition format"}
    end
  end

  defp validate_record_fields(ctx, fields) do
    Enum.reduce_while(fields, :ok, fn {_field_name, field_type}, :ok ->
      case validate_type(ctx, field_type) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_foreign_import_metadata(_ctx, metadata) do
    required_keys = ["ffi_name", "ffi_module", "arity", "arg_types", "return_type"]
    atom_keys = [:ffi_name, :ffi_module, :arity, :arg_types, :return_type]

    has_required =
      Enum.all?(required_keys, &Map.has_key?(metadata, &1)) or
        Enum.all?(atom_keys, &Map.has_key?(metadata, &1))

    if has_required do
      :ok
    else
      {:error, "Foreign import metadata missing required keys: #{inspect(required_keys)}"}
    end
  end

  defp validate_function_metadata(_ctx, _metadata) do
    # Add specific validation logic for function metadata as needed
    :ok
  end

  defp validate_constructor(ctx, constructor) do
    if type_exists?(ctx, constructor) do
      :ok
    else
      {:error, "Unknown type constructor: #{constructor}"}
    end
  end

  defp validate_type_vars(ctx, vars) when is_list(vars) do
    Enum.reduce_while(vars, :ok, fn var, :ok ->
      case validate_type(ctx, var) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  @doc """
  Pretty prints a parsed type.
  """
  def format_type(type) do
    case type do
      name when is_binary(name) ->
        name

      %{constructor: constructor, vars: []} ->
        constructor

      %{constructor: constructor, vars: vars} ->
        formatted_vars = vars |> Enum.map(&format_type/1) |> Enum.join(", ")
        "#{constructor}<#{formatted_vars}>"
    end
  end
end
