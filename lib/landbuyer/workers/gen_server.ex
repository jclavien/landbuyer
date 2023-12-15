defmodule Landbuyer.Workers.GenServer do
  use GenServer, restart: :transient

  alias Landbuyer.Workers.State

  def start_link(%State{name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: {:via, Registry, {:traders_registry, name}})
  end

  @impl true
  def init(%State{account: account, trader: trader} = state) do
    IO.puts("> Init GenServer #{"A#{account.id}/T#{trader.id}"}")
    IO.puts("  Account:")
    IO.inspect(account)
    IO.puts("  Trader:")
    IO.inspect(trader)

    Process.send_after(self(), :beat, trader.rate_ms)

    {:ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info(:beat, %State{account: account, trader: trader} = state) do
    IO.puts("> Beat GenServer #{"A#{account.id}/T#{trader.id}"}")

    Process.send_after(self(), :beat, trader.rate_ms)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %State{account: account, trader: trader}) do
    IO.puts("> Kill GenServer #{"A#{account.id}/T#{trader.id}"} (from GenServer)")
    :ok
  end
end
