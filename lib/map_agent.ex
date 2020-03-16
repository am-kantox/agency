defmodule MapAgent do
  @moduledoc false

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
    @callback unquote(:"handle_#{fun}")(value) :: value when value: any()
  end)

  @doc """
  The callback that is called from `this/0` right after
    the `Agent` has returned the value, passing this value as
    a parameter.
  """
  @callback handle_this(value) :: value when value: any()

  # @doc """
  # The callback that is called from `size/0` right after
  #   the `Agent` has returned the value, passing this value as
  #   a parameter.
  # """
  # @callback handle_size(value) :: value when value: non_neg_integer()

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
            quote(do: use(MapAgent.Scaffold, unquote(opts))),
            Macro.Env.location(__ENV__)
          )

        module
    end
  end

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MapAgent.Scaffold, opts
    end
  end
end
