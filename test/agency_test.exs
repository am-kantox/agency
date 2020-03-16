defmodule Agency.Test do
  use ExUnit.Case, async: true

  setup_all do
    {:ok, pid} = TestAgency.start_link()
    {:ok, pid1} = TestAgency1.start_link()
    {:ok, pid2} = TestAgency2.start_link()

    on_exit(fn ->
      Process.exit(pid2, :normal)
      Process.exit(pid1, :normal)
      Process.exit(pid, :normal)
    end)
  end

  test "Agency.this/0" do
    assert TestAgency1.this() == %{}
    assert TestAgency1.put(:v1, 42) == :ok
    assert TestAgency1.this() == %{v1: 42}
  end

  test "Agency.put/2" do
    assert TestAgency2.get(:v2) == nil
    assert TestAgency2.put(:v2, 42) == :ok
    assert %{v2: 42} = TestAgency2.this()
  end

  test "Agency.get/1" do
    assert TestAgency2.get(:v3) == nil
    assert TestAgency2.put(:v3, 42) == :ok
    assert TestAgency2.get(:v3) == 42
  end

  test "Agency.get/1 with after_get" do
    assert TestAgency.put(:v3, 42) == :ok
    assert TestAgency.get(:v3) == 84
  end

  test "Agency.get_and_update/2" do
    assert is_nil(TestAgency2.get_and_update(:v4, &{&1, 42}))
    assert TestAgency2.get_and_update(:v4, &{&1, &1 + 1}) == 42
  end

  test "Agency.update/3" do
    assert TestAgency2.get(:v5) == nil
    assert TestAgency2.update(:v5, fn nil -> 42 end) == :ok
    assert TestAgency2.get(:v5) == 42
    assert TestAgency2.update(:v5, &(&1 + 1)) == :ok
    assert TestAgency2.get(:v5) == 43
  end

  test "Agency.pop/1" do
    assert TestAgency2.put(:v6, 42) == :ok
    assert TestAgency2.put(:v7, 42) == :ok
    assert {42, %{v7: 42}} = TestAgency2.pop(:v6)
  end
end
