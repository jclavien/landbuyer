defmodule Landbuyer.Workers.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Landbuyer.Accounts
  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader
  alias Landbuyer.Workers

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec maybe_spawn_active_traders() :: :ok
  def maybe_spawn_active_traders do
    Enum.each(Accounts.get_all(), fn account ->
      Enum.each(account.traders, fn trader -> create_worker(account, trader) end)
    end)
  end

  @spec create_worker(Account.t(), Trader.t()) :: :ignore | {:error, any()} | {:ok, pid()} | {:ok, pid(), any()}
  def create_worker(account, %Trader{state: :active} = trader) do
    worker_state =
      %Workers.State{
        name: trader.id,
        account: %{account | traders: nil},
        trader: trader,
        data: %{}
      }

    DynamicSupervisor.start_child(Workers.Supervisor, {Workers.GenServer, worker_state})
  end

  def create_worker(_account, _trader), do: :ignore

  @spec pause_worker(integer()) :: :ok
  def pause_worker(name) do
    GenServer.call({:via, Registry, {:traders_registry, name}}, :stop)
  end
end
