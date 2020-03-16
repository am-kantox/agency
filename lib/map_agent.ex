defmodule MapAgent do
  @moduledoc false

  @rejected [replace: 3, size: 1]
  @functions :functions |> Map.__info__() |> Enum.reject(&(&1 in @rejected))

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
  The callback that is called from `all/0` right after
    the `Agent` has returned the value, passing this value as
    a parameter.
  """
  @callback handle_all(value) :: value when value: map()

  @doc """
  The callback that is called from `size/0` right after
    the `Agent` has returned the value, passing this value as
    a parameter.
  """
  @callback handle_size(value) :: value when value: non_neg_integer()

  @doc """
  Creates an `Agent` module.

  If the module is already loaded, this is a no-op.
  """
  @spec agent!(name :: binary() | atom()) :: module()
  def agent!(name) when is_binary(name),
    do: agent!(Module.concat(__MODULE__, String.capitalize(name)))

  def agent!(name) when is_atom(name) do
    case Code.ensure_compiled(name) do
      {:module, module} ->
        module

      {:error, _reason} ->
        {:module, module, _, _} =
          Module.create(name, quote(do: use(MapAgent.Scaffold)), Macro.Env.location(__ENV__))

        module
    end
  end
end
