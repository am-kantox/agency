defmodule MapAgent.Scaffold do
  @moduledoc false

  @functions MapAgent.__functions__()

  # delegates
  Enum.each(@functions, fn {fun, arity} ->
    defdelegate unquote(fun)(unquote_splicing(Macro.generate_arguments(arity, __MODULE__))),
      to: Map
  end)

  def all(map), do: map
  def size(map), do: map_size(map)

  # default implementations
  @default_implementation_ast [
    quote(do: defoverridable(MapAgent)),
    quote do
      @doc false
      def handle_all(value), do: value
      @doc false
      def handle_size(value), do: value
    end
    | Enum.map(@functions, fn {fun, arity} ->
        quote do
          @doc false
          def unquote(:"handle_#{fun}")(value), do: value
        end
      end)
  ]

  @doc false
  defmacro __using__(opts) do
    [
      quote location: :keep do
        @behaviour MapAgent

        use Agent

        @name Keyword.get(unquote(opts), :name, __MODULE__)
        @into Keyword.get(unquote(opts), :into, %{})
        @handler Keyword.get(unquote(opts), :handler, MapAgent.Scaffold)

        @doc """
        Starts the `Agent` that backs up the container
          (defaulted to `Map`.)

        The argument passed to the function is ignored.
        """
        @spec start_link(opts :: keyword()) :: GenServer.on_start()
        def start_link(_opts \\ []),
          do: Agent.start_link(fn -> @into end, name: @name)

        @doc """
        Returns the whole container, backed up by the `Agent`.
        """
        @spec all() :: map()
        def all() do
          @name
          |> Agent.get(@handler, :all, [])
          |> handle_all()
        end

        @doc """
        Returns the size of the container, backed up by the `Agent`.
        """
        @spec size() :: non_neg_integer()
        def size() do
          @name
          |> Agent.get(@handler, :size, [])
          |> handle_size()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`.
        """
        @spec get(Map.key()) :: Map.value()
        def get(key) do
          @name
          |> Agent.get(@handler, :get, [key])
          |> handle_get()
        end

        @doc """
        Put the `value` under the specific `key` to the container,
          backed up by the `Agent`.
        """
        @spec put(Map.key(), Map.value()) :: map()
        def put(key, value) do
          @name
          |> Agent.update(@handler, :put, [key, value])
          |> handle_put()
        end

        @doc """
        Update the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec update(Map.key(), Map.value(), (Map.value() -> Map.value())) :: map()
        def update(key, initial, fun) do
          @name
          |> Agent.update(@handler, :update, [key, initial, fun])
          |> handle_update()
        end

        @doc """
        Delete the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec delete(Map.key()) :: map()
        def delete(key) do
          @name
          |> Agent.update(@handler, :delete, [key])
          |> handle_delete()
        end
      end
      | @default_implementation_ast
    ]
  end
end
