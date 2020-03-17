defmodule TestAgency do
  @moduledoc false
  use Agency

  def before_put(_key), do: [:foo]
  def after_get(value), do: to_string(value)
end
