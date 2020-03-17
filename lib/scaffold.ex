defmodule Agency.Scaffold do
  @moduledoc false

  @access_impl_ast Agency.Impl.access_impl_ast()
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

        @raw_data Keyword.get(unquote(opts), :data, name: __MODULE__)
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
        def start_link(_opts \\ []),
          do: Agent.start_link(fn -> @into end, name: __MODULE__)

        @doc """
        Returns the whole container, backed up by the `Agent`.
        """
        @spec this() :: Access.t()
        def this do
          __MODULE__
          |> Agent.get(Agency.Scaffold, :this, [])
          |> after_this()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`.
        """
        @spec get(Agency.key() | Agency.keys()) :: Agency.value()
        def get(key) when not is_list(key), do: get([key])

        def get(key) do
          __MODULE__
          |> Agent.get(Kernel, :get_in, [key])
          |> after_get()
        end

        @doc """
        Get the value for the specific `key` from the container,
          backed up by the `Agent`, and updates it.
        """
        @spec get_and_update(
                Agency.key() | Agency.keys(),
                (term() -> {get_value, update_value} | :pop)
              ) :: get_value
              when get_value: Agency.value(), update_value: Agency.value()
        def get_and_update(key, fun) when not is_list(key),
          do: get_and_update([key], fun)

        def get_and_update(key, fun) do
          __MODULE__
          |> Agent.get_and_update(Kernel, :get_and_update_in, [key, fun])
          |> after_get_and_update()
        end

        @doc """
        Pops the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec pop(Agency.key() | Agency.keys()) :: Access.t()
        def pop(key) when not is_list(key), do: pop([key])

        def pop(key) do
          {value, container} = pop_in(this(), key)
          Agent.update(__MODULE__, Agency.Scaffold, :this, [container])
          after_pop({value, container})
        end

        @doc """
        Put the `value` under the specific `key` to the container,
          backed up by the `Agent`.
        """
        @spec put(Agency.key() | Agency.keys(), Agency.value()) :: Access.t()
        def put(key, value) when not is_list(key), do: put([key], value)

        def put(key, value) do
          __MODULE__
          |> Agent.update(Kernel, :put_in, [key, value])
          |> after_put()
        end

        @doc """
        Update the `value` for the specific `key` in the container,
          backed up by the `Agent`.
        """
        @spec update(Agency.key() | Agency.keys(), (Agency.value() -> Agency.value())) ::
                Access.t()
        def update(key, fun) when not is_list(key), do: update([key], fun)

        def update(key, fun) do
          __MODULE__
          |> Agent.update(Kernel, :update_in, [key, fun])
          |> after_update()
        end
      end,
      @access_impl_ast | @agency_impl_ast
    ]
  end
end
