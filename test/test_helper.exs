MapAgent.agent!(TestMapAgent0)
MapAgent.agent!(TestMapAgent1, into: %{})
MapAgent.agent!(TestMapAgent2, into: %{})

defmodule TestMapAgent do
  use MapAgent

  def after_get(value), do: value * 2
end

ExUnit.start()
