defmodule Landbuyer.Workers.GenServer do
  use GenServer, restart: :transient

  alias Landbuyer.Workers.State

  def start_link(%State{name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: {:via, Registry, {:traders_registry, name}})
  end

  @impl true
  def init(%State{trader: trader} = state) do
    # Precompute strategy module
    strategy =
      Landbuyer.Strategies.Strategies.all()
      |> Enum.find(fn strategy -> strategy.key() == trader.strategy end)

    state = %{state | data: Map.put(state.data, :strategy, strategy)}

    Process.send_after(self(), :run_strategy, trader.rate_ms)
    {:ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info(:run_strategy, %State{account: account, trader: trader, data: %{strategy: strategy}} = state) do
    resp = strategy.run(account, trader)

    # TODO: Record resp in database
    IO.puts("A#{account.id}T#{trader.id} > #{inspect(resp)}")

    Process.send_after(self(), :run_strategy, trader.rate_ms)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
