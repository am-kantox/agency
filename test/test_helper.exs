MapAgent.agent!(TestMapAgent)
MapAgent.agent!(TestMapAgent1, into: %{})
MapAgent.agent!(TestMapAgent2, into: %{})

ExUnit.start()
