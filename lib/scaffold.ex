defmodule Agency.Scaffold do
  @moduledoc false

  # credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks

  @agency_impl_ast Agency.Impl.agency_impl_ast()

  def this(container), do: container
  def this(_, container), do: container

  @doc false
  defmacro __using__(opts) do
    [
      quote location: :keep do
        @into Keyword.get(unquote(opts), :into, %{})

        @moduledoc """
        The `Agent` backing up the `#{inspect(@into)}` instance.
        """

        @behaviour Agency
        @behaviour Access

        @name Keyword.get(unquote(opts), :name, __MODULE__)

        @raw_data Keyword.get(unquote(opts), :data, name: @name)
        @data for {k, v} <- @raw_data, do: {k, v}
        defstruct @data

        use Agent

        @doc """
        Returns a thing that might be used in `Kernel.***_in`
          function family.
        """
        @spec access() :: Access.t()
        def access, do: %__MODULE__{}

        @doc """
        Starts the `Agent` that backs up the container
          (defaulted to `Map`.)

        The argument passed to the function is ignored.
        """
        @spec start_link(opts :: keyword()) :: GenServer.on_start()
        def start_link(opts \\ []) do
          name = Keyword.get(opts, :name, @name)
          Agent.start_link(fn -> @into end, name: name)
        end

        @doc """
        Returns the whole container, backed up by the `Agent`.
        """
        @spec this(GenServer.name()) :: Access.t()
        def this(name \\ @name) do
          name
          |> Agent.get(Agency.Scaffold, :this, [])
          |> after_this()
        end

        @impl Access
        def fetch(%data{}, key) do
          case data.get(key) do
            nil -> :error
            found -> {:ok, found}
          end
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`.
        """
        @spec get(GenServer.name(), Agency.keyz()) :: Agency.value()
        def get(name \\ @name, key)

        def get(name, key) when not is_list(key),
          do: get(name, [key])

        def get(name, key) do
          key = key |> before_all() |> before_get()

          name
          |> Agent.get(Kernel, :get_in, [key])
          |> after_get()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`, and updates it.
        """
        @spec get_and_update(
                GenServer.name() | struct(),
                Agency.keyz(),
                (Agency.value() -> {get_value, update_value} | :pop)
              ) :: {get_value, Access.container()}
              when get_value: Agency.value(), update_value: Agency.value()
        def get_and_update(name \\ @name, key, fun)

        @impl Access
        def get_and_update(%data{}, key, fun) do
          old_value = data.get(key)

          case fun.(old_value) do
            :pop ->
              data.pop(key)

            {get_value, update_value} ->
              data.put(key, update_value)
              {get_value, data}
          end
        end

        def get_and_update(name, key, fun) when not is_list(key),
          do: get_and_update(name, [key], fun)

        def get_and_update(name, key, fun) do
          key = key |> before_all() |> before_get_and_update()

          name
          |> Agent.get_and_update(Kernel, :get_and_update_in, [key, fun])
          |> after_get_and_update()
        end

        @doc """
        Pops the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec pop(GenServer.name() | struct(), Agency.keyz()) ::
                {Agency.value(), Access.container()}
        def pop(name \\ @name, key)

        @impl Access
        def pop(%data{}, key) do
          data.pop(key)
        end

        def pop(name, key) when not is_list(key),
          do: pop(name, [key])

        def pop(name, key) do
          key = key |> before_all() |> before_pop()
          {value, container} = pop_in(this(), key)
          Agent.update(name, Agency.Scaffold, :this, [container])
          after_pop({value, container})
        end

        @doc """
        Put the `value` under the specific `key` to the container,
          backed up by the `Agent`.
        """
        @spec put(GenServer.name(), Agency.keyz(), Agency.value()) :: :ok
        def put(name \\ @name, key, value)

        def put(name, key, value) when not is_list(key),
          do: put(name, [key], value)

        def put(name, key, value) do
          key = key |> before_all() |> before_put()

          name
          |> Agent.update(Kernel, :put_in, [key, value])
          |> after_put()
        end

        @doc """
        Update the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec update(GenServer.name(), Agency.keyz(), (Agency.value() -> Agency.value())) :: :ok
        def update(name \\ @name, key, fun)

        def update(name, key, fun) when not is_list(key),
          do: update(name, [key], fun)

        def update(name, key, fun) do
          key = key |> before_all() |> before_update()

          name
          |> Agent.update(Kernel, :update_in, [key, fun])
          |> after_update()
        end
      end
      | @agency_impl_ast
    ]
  end
end
