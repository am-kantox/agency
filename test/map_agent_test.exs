defmodule MapAgent.Test do
  use ExUnit.Case, async: true

  setup_all do
    {:ok, pid1} = TestMapAgent1.start_link()
    {:ok, pid2} = TestMapAgent2.start_link()

    on_exit(fn ->
      Process.exit(pid2, :normal)
      Process.exit(pid1, :normal)
    end)
  end

  test "MapAgent.size/0 + MapAgent.all/0" do
    assert TestMapAgent1.size() == 0
    assert TestMapAgent1.all() == %{}
    assert TestMapAgent1.put(:v1, 42) == :ok
    assert TestMapAgent1.size() == 1
    assert TestMapAgent1.all() == %{v1: 42}
  end

  test "MapAgent.put/2" do
    assert TestMapAgent2.get(:v2) == nil
    assert TestMapAgent2.put(:v2, 42) == :ok
    assert %{v2: 42} = TestMapAgent2.all()
  end

  test "MapAgent.get/1" do
    assert TestMapAgent2.get(:v3) == nil
    assert TestMapAgent2.put(:v3, 42) == :ok
    assert TestMapAgent2.get(:v3) == 42
  end

  test "MapAgent.update/3" do
    assert TestMapAgent2.get(:v4) == nil
    assert TestMapAgent2.update(:v4, 42, fn _ -> nil end) == :ok
    assert TestMapAgent2.get(:v4) == 42
    assert TestMapAgent2.update(:v4, 42, &(&1 + 1)) == :ok
    assert TestMapAgent2.get(:v4) == 43
  end
end
