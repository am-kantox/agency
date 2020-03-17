defmodule Agency.Test do
  use ExUnit.Case, async: true

  setup_all do
    {:ok, pid} = TestAgency.start_link()
    {:ok, pid1} = TestAgency1.start_link()
    {:ok, pid2} = TestAgency2.start_link()
    {:ok, pid3} = TestAgency3.start_link()
    {:ok, pid4} = TestAgency4.start_link(name: TA4)

    on_exit(fn ->
      Process.exit(pid4, :normal)
      Process.exit(pid3, :normal)
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

  test "Agency.get/1 with after_get and before_put" do
    assert TestAgency.put(:v3, 42) == :ok
    assert TestAgency.get(:v3) == ""
    assert TestAgency.get(:foo) == "42"
  end

  test "Agency.get_and_update/2" do
    assert is_nil(TestAgency2.get_and_update(:v4, &{&1, 42}))
    assert TestAgency2.get_and_update(:v4, &{&1, &1 + 1}) == 42
    assert TestAgency2.get_and_update(:v4, fn _ -> :pop end) == 43
    assert nil == TestAgency2.get(:v4)
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

  test "Agency Access" do
    assert TestAgency3.put(:v8, %{v9: 42}) == :ok
    assert get_in(TestAgency3.access(), [:v8, :v9]) == 42
    assert pop_in(TestAgency3.access(), [:v8, :v9]) == {42, TestAgency3}
  end

  test "Named Agency" do
    assert TestAgency4.put(TA4, :v8, 42) == :ok
    assert TestAgency4.get(TA4, :v8) == 42

    Process.flag(:trap_exit, true)
    pid = spawn_link(fn -> TestAgency4.get(:v8) end)

    assert_receive {:EXIT, ^pid,
                    {:noproc,
                     {GenServer, :call, [TestAgency4, {:get, {Kernel, :get_in, [[:v8]]}}, 5000]}}}
  end

  test "Multiple named instances of Agency" do
    assert {:ok, pid1} = TestAgency5.start_link(name: TA5_1)
    assert {:ok, pid2} = TestAgency5.start_link(name: TA5_2)
    assert Process.alive?(pid1)
    assert Process.alive?(pid2)

    assert TestAgency5.put(TA5_1, :v5_1, 42) == :ok
    assert TestAgency5.get(TA5_1, :v5_1) == 42
    assert TestAgency5.put(TA5_2, :v5_1, :bar) == :ok
    assert TestAgency5.get(TA5_2, :v5_1) == :bar
    assert TestAgency5.get(TA5_1, :v5_1) == 42

    Process.exit(pid1, :normal)
    assert Process.alive?(pid2)
    Process.exit(pid2, :normal)
  end
end
