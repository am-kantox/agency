defmodule Agency.Impl do
  @moduledoc false

  #########################################################
  ####################### AGENCY ##########################
  #########################################################

  @functions Agency.__functions__()

  def agency_impl_ast do
    :lists.reverse([
      quote(do: defoverridable(Agency)),
      quote do
        @impl Agency
        def before_all(key), do: key

        @impl Agency
        def after_this(value), do: value
      end
      | Enum.map(@functions, fn {fun, _arity} ->
          quote do
            @impl Agency
            def unquote(:"before_#{fun}")(key), do: key
            @impl Agency
            def unquote(:"after_#{fun}")(value), do: value
          end
        end)
    ])
  end
end
