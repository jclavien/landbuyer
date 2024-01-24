defmodule Landbuyer.Workers.GenServer do
  @moduledoc false
  use GenServer, restart: :transient

  alias Landbuyer.Accounts
  alias Landbuyer.Workers.State

  def start_link(%State{name: name} = state) do
    GenServer.start_link(__MODULE__, state, name: {:via, Registry, {:traders_registry, name}})
  end

  @impl true
  def init(%State{trader: trader} = state) do
    # Precompute strategy module
    strategy =
      Enum.find(Landbuyer.Strategies.Strategies.all(), fn strategy -> strategy.key() == trader.strategy end)

    # Set working data for the task
    data =
      state.data
      |> Map.put(:strategy, strategy)
      |> Map.put(:counter, 0)

    state = %{state | data: data}

    # Start the task
    Process.send_after(self(), :run_strategy, 0)
    {:ok, state}
  end

  @impl true
  def handle_info(:run_strategy, %State{trader: trader} = state) do
    state = run_task(state)
    Process.send_after(self(), :run_strategy, trader.rate_ms)
    {:noreply, state}
  end

  @impl true
  def handle_call(:stop, _from, %State{account: account, trader: trader, data: %{counter: counter}} = state) do
    IO.puts("#{format_ids(account.id, trader.id)} | End of task after #{counter} iterations")
    {:stop, :normal, :ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end

  defp run_task(%State{account: account, trader: trader, data: %{strategy: strategy, counter: counter}} = state) do
    # Run the strategy
    events = strategy.run(account, trader)

    # Maybe do batch insert here?
    # Maybe do insert in a task here?
    Enum.each(events, fn {type, reason, message} ->
      event_params = %{type: type, reason: Atom.to_string(reason), message: message}

      case Accounts.create_event(trader, event_params) do
        {:ok, event} -> event
        {:error, _reason} -> :error
      end
    end)

    # Increment counter
    %{state | data: %{state.data | counter: counter + 1}}
  end

  defp format_ids(account_id, trader_id) do
    account_id = String.pad_trailing("#{account_id}", 3, " ")
    trader_id = String.pad_trailing("#{trader_id}", 3, " ")
    "A#{account_id}T#{trader_id}"
  end
end
