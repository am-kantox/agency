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

  #########################################################
  ####################### ACCESS ##########################
  #########################################################

  def access_impl_ast do
    quote do
      @impl Access
      def fetch(%data{}, key) do
        case data.get(key) do
          nil -> :error
          found -> {:ok, found}
        end
      end

      @impl Access
      def pop(%data{}, key) do
        data.pop(key)
      end

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
    end
  end
end
