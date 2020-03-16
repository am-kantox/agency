defmodule MapAgent.Scaffold do
  @moduledoc false

  @functions MapAgent.__functions__()

  def this(container), do: container

  # default implementations
  @default_implementation_ast [
    quote(do: defoverridable(MapAgent)),
    quote do
      @doc false
      def handle_this(value), do: value
    end
    | Enum.map(@functions, fn {fun, _arity} ->
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
        @spec this() :: Access.t()
        def this() do
          @name
          |> Agent.get(MapAgent.Scaffold, :this, [])
          |> handle_this()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`.
        """
        @spec get(MapAgent.key()) :: MapAgent.value()
        def get(key) do
          @name
          |> Agent.get(Kernel, :get_in, [[key]])
          |> handle_get()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`, and updates it.
        """
        @spec get_and_update(MapAgent.key(), (term() -> {get_value, update_value} | :pop)) ::
                {get_value, Access.t()}
              when get_value: MapAgent.value(), update_value: MapAgent.value()
        def get_and_update(key, fun) do
          @name
          |> Agent.get(Kernel, :get_and_update_in, [[key], fun])
          |> handle_get_and_update()
        end

        @doc """
        Pops the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec pop(MapAgent.key()) :: Access.t()
        def pop(key) do
          @name
          |> Agent.update(Kernel, :pop_in, [[key]])
          |> handle_pop()
        end

        @doc """
        Put the `value` under the specific `key` to the container,
          backed up by the `Agent`.
        """
        @spec put(MapAgent.key(), MapAgent.value()) :: Access.t()
        def put(key, value) do
          @name
          |> Agent.update(Kernel, :put_in, [[key], value])
          |> handle_put()
        end

        @doc """
        Update the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec update(MapAgent.key(), (MapAgent.value() -> MapAgent.value())) :: Access.t()
        def update(key, fun) do
          @name
          |> Agent.update(Kernel, :update_in, [[key], fun])
          |> handle_update()
        end
      end
      | @default_implementation_ast
    ]
  end
end
