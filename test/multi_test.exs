defmodule Agency.Multi.Test do
  use ExUnit.Case, async: true
  doctest Agency.Multi

  setup_all do
    {:ok, pid} = Agency.Multi.start_link(count: 5)

    on_exit(fn -> Process.exit(pid, :normal) end)
  end

  test "children" do
    assert Agency.Multi.Dyno |> DynamicSupervisor.which_children() |> Enum.count() == 5
  end

  test "Agency.{get/1, put/2}" do
    assert Agency.Multi.get(:v2) == nil
    assert Agency.Multi.put(:v2, 42) == :ok
    assert Agency.Multi.get(:v2) == 42
  end

  test "Agency.update/3" do
    assert Agency.Multi.get(:v5) == nil
    assert Agency.Multi.update(:v5, fn nil -> 42 end) == :ok
    assert Agency.Multi.get(:v5) == 42
    assert Agency.Multi.update(:v5, &(&1 + 1)) == :ok
    assert Agency.Multi.get(:v5) == 43
  end
end
