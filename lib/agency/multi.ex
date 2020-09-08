case Code.ensure_compiled(HashRing.Managed) do
  {:module, HashRing.Managed} ->
    defmodule Agency.Multi do
      @moduledoc """
      `Supervisor` managing a hashring of agents behind.

      It starts a `DynamicSupervisor` that takes care of all the ringed children.
      """

      defmodule Dyno do
        @moduledoc false
        use DynamicSupervisor

        @spec start_link(keyword()) :: GenServer.on_start()
        def start_link(opts \\ []),
          do: DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)

        @impl true
        def init(_opts),
          do: DynamicSupervisor.init(strategy: :one_for_one)
      end

      defmodule Init do
        @moduledoc false
        use GenServer

        @spec start_link(keyword()) :: GenServer.on_start()
        def start_link(opts),
          do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

        @impl true
        def init(opts) do
          if Keyword.get(opts, :lazy?, false) do
            {:ok, opts, {:continue, :children}}
          else
            {:noreply, opts} = handle_continue(:children, opts)
            {:ok, opts}
          end
        end

        @impl true
        def handle_continue(:children, opts) do
          for i <- 0..opts[:count], i > 0 do
            name =
              opts[:agent_opts]
              |> Keyword.get(:name, opts[:agent])
              |> Module.concat("Agent_#{i}")

            agent_opts = Keyword.put(opts[:agent_opts], :name, name)
            spec = %{id: agent_opts[:name], start: {opts[:agent], :start_link, [agent_opts]}}

            DynamicSupervisor.start_child(Dyno, spec)
            HashRing.Managed.add_node(Module.concat(opts[:name], "Ring"), agent_opts[:name])
          end

          {:noreply, opts}
        end
      end

      use Supervisor

      @type option ::
              {:count, integer()}
              | {:name, atom()}
              | {:agent, module()}
              | {:agent_opts, keyword()}
      @type options :: [option()]

      @spec start_link(opts :: options()) :: GenServer.on_start()
      @doc """
      Starts the supervisor for multy-agency.
      """
      def start_link(opts \\ []) do
        opts =
          opts
          |> Keyword.put_new(:count, 0)
          |> Keyword.put_new(:name, __MODULE__)
          |> Keyword.put_new(:agent, Agency.Default)
          |> Keyword.put_new(:agent_opts, [])

        Supervisor.start_link(__MODULE__, opts, name: opts[:name])
      end

      @impl true
      @doc false
      def init(opts) do
        ring = Module.concat(opts[:name], "Ring")
        {:ok, _pid} = HashRing.Managed.new(ring)
        Process.put(:ring, ring)
        Supervisor.init([{Dyno, []}, {Init, opts}], strategy: :rest_for_one)
      end

      Enum.each(Agency.__functions__(), fn {fun, arity} ->
        args = Macro.generate_arguments(arity, __MODULE__)

        @doc "Routes the call to the proper agent based on hashring"
        def unquote(fun)(unquote_splicing(args)) do
          [key | _] = args = [unquote_splicing(args)]

          :ring
          |> Process.get(Module.concat(__MODULE__, "Ring"))
          |> HashRing.Managed.key_to_node(key)
          |> case do
            {:error, {:invalid_ring, :no_nodes}} ->
              unquote(fun)(unquote_splicing(args))

            agent ->
              agent_module =
                agent |> Module.split() |> Enum.split(-1) |> elem(0) |> Module.concat()

              apply(agent_module, unquote(fun), [agent | args])
          end
        end
      end)
    end

  {:error, _error} ->
    require Logger

    Logger.warn("""
    Multi-agent functionality is disabled.
    Explicitly add `libring` to the dependencies to enable it.
    """)
end
