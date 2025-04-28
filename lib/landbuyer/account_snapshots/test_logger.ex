defmodule Landbuyer.AccountSnapshots.TestLogger do
  @moduledoc false
  use GenServer

  alias Landbuyer.AccountSnapshots.AccountSnapshot
  alias Landbuyer.Repo

  require Logger

  @doc """
  Démarre le TestLogger.

  ## Options

    * :rate_ms    – intervalle en millisecondes (default 30_000)
    * :account_id – l’ID du compte (obligatoire)
    * :initial_nav – valeur de départ du NAV (default Decimal.new(2000))
  """
  def start_link(opts) when is_list(opts) do
    rate_ms = Keyword.get(opts, :rate_ms, 30_000)
    account_id = Keyword.fetch!(opts, :account_id)
    initial_nav = Keyword.get(opts, :initial_nav, Decimal.new(2000))
    GenServer.start_link(__MODULE__, {rate_ms, account_id, initial_nav})
  end

  @impl true
  def init({rate_ms, account_id, initial_nav}) do
    Logger.info("[TestLogger] Démarré avec account_id = #{account_id}")
    schedule_tick(rate_ms)
    {:ok, %{rate_ms: rate_ms, account_id: account_id, nav: initial_nav}}
  end

  @impl true
  def handle_info(:run_strategy, %{rate_ms: rate_ms, account_id: id, nav: last_nav} = state) do
    # génère un coefficient aléatoire entre -0.01 et +0.01
    fluctuation = (:rand.uniform() * 2 - 1) * 0.01

    # calcule le nouveau NAV
    last_value = Decimal.to_float(last_nav)
    new_value = last_value * (1 + fluctuation)
    new_nav = Decimal.from_float(new_value)

    # insertion en base
    %AccountSnapshot{}
    |> AccountSnapshot.changeset(%{account_id: id, nav: new_nav})
    |> Repo.insert!()

    # re-planifie le prochain tick
    schedule_tick(rate_ms)

    # met à jour le state avec le nouveau NAV
    {:noreply, %{state | nav: new_nav}}
  end

  defp schedule_tick(rate_ms) do
    Process.send_after(self(), :run_strategy, rate_ms)
  end
end
