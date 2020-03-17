Agency.agent!(TestAgency0)
Agency.agent!(TestAgency1, name: TA1)
Agency.agent!(TestAgency2, into: %{})
Agency.agent!(TestAgency3, data: %{name: "Agent", pi: 3.14})
Agency.agent!(TestAgency4)
Agency.agent!(TestAgency5)

ExUnit.start()
