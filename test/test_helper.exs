Agency.agent!(TestAgency0)
Agency.agent!(TestAgency1, into: %{})
Agency.agent!(TestAgency2, into: %{})
Agency.agent!(TestAgency3, data: %{name: "Agent", pi: 3.14})

defmodule TestAgency do
  use Agency

  def before_put(_key), do: [:foo]
  def after_get(value), do: to_string(value)
end

ExUnit.start()
