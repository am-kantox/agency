Agency.agent!(TestAgency0)
Agency.agent!(TestAgency1, into: %{})
Agency.agent!(TestAgency2, into: %{})

defmodule TestAgency do
  use Agency

  def after_get(value), do: value * 2
end

ExUnit.start()
