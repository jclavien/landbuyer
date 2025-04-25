defmodule Landbuyer.AccountSnapshots.TestLogger do
  @moduledoc false
  use GenServer

  alias Landbuyer.AccountSnapshots.AccountSnapshot
  alias Landbuyer.Repo

  @interval :timer.seconds(30)
  @default_account_id 3

  ## === Public API ===

  # On récupère l'account_id passé ou on retombe sur @default_account_id
  def start_link(opts \\ []) do
    account_id = Keyword.get(opts, :account_id, @default_account_id)
    GenServer.start_link(__MODULE__, account_id, name: __MODULE__)
  end

  ## === Callbacks ===

  # now the state is simply the integer account_id
  def init(account_id) when is_integer(account_id) do
    IO.puts("[TestLogger] Démarré avec account_id = #{account_id}")
    schedule_tick()
    {:ok, account_id}
  end

  def handle_info(:tick, account_id) do
    nav = Float.round(950 + :rand.uniform() * 100, 2)

    Repo.insert!(%AccountSnapshot{account_id: account_id, nav: nav})
    IO.puts("[TestLogger] Nouveau snapshot NAV = #{nav}")
    schedule_tick()
    {:noreply, account_id}
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @interval)
end
