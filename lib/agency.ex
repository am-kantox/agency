defmodule Agency do
  @moduledoc """
  `Agency` is an abstraction layer above `Agent` allowing to use any
  container supporting `Access` behind and simplifying the client API
  handling.

  `Agency` itself implements `Access` behaviour, making it possible to
  embed instances in the middle of `Access.keys` chains.

  In a nutshell, `Agency` backs up the `Agent` holding a container.
  All the standard CRUD-like calls are done through containers’
  `Access` implementation, allowing transparent shared access.

  The set of `after_***/1` functions are introduced, so that the main
  `Agent` feature distinguishing it from the standard `GenServer`
  holding state—namely, a separation of client and server APIs—is
  exposed transparently to the consumers.

  Consider the following example.

  ```elixir
  defmodule MyAgent do
    use Agency, into: %{} # default

    def after_get(value) do
      value + 1
    end

    ...
  end
  ```

  The above code introduces an `Agent` backing up `Map` and
  exposes the standard CRUD-like functionality. After the value
  would be got from the server API, it’d be increased by `1`
  and returned to the consumer.

  ### Options

  `use Agency` accepts two options:

  - `into: Access.t()` the container to be used by `Agent`
  - `data: map() | keyword()` the static data to be held by the instances

  ---

  One might also pass any struct, or whatever else implementing
  `Access` as `into:` option to be used as an `Agent` container.
  """

  @type key :: any()
  @type keys :: [key()]
  @type value :: any()

  @functions [
    get: 2,
    get_and_update: 3,
    pop: 2,
    put: 3,
    update: 2
  ]

  @doc false
  def __functions__, do: @functions

  # callbacks
  Enum.each(@functions, fn {fun, arity} ->
    @doc """
    The callback that is called from `#{fun}/#{arity}` right after
      the `Agent` has returned the value, passing this value as
      a parameter.
    """
    @callback unquote(:"after_#{fun}")(value) :: value when value: any()
  end)

  @doc """
  The callback that is called from `this/0` right after
    the `Agent` has returned the value, passing this value as
    a parameter.
  """
  @callback after_this(value) :: value when value: any()

  @doc """
  Creates an `Agent` module.

  If the module is already loaded, this is a no-op.
  """
  @spec agent!(name :: binary() | atom()) :: module()
  def agent!(name, opts \\ [])

  def agent!(name, opts) when is_binary(name),
    do: agent!(Module.concat(__MODULE__, String.capitalize(name)), opts)

  def agent!(name, opts) when is_atom(name) do
    opts = Macro.escape(opts)

    case Code.ensure_compiled(name) do
      {:module, module} ->
        module

      {:error, _reason} ->
        {:module, module, _, _} =
          Module.create(
            name,
            quote(do: use(Agency.Scaffold, unquote(opts))),
            Macro.Env.location(__ENV__)
          )

        module
    end
  end

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Agency.Scaffold, opts
    end
  end
end
