defmodule Landbuyer.Accounts do
  @moduledoc """
  This module contains all the logic related to the accounts.
  """

  import Ecto.Query

  alias Landbuyer.Repo
  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Event
  alias Landbuyer.Schemas.Trader

  @spec get(integer()) :: {:ok, Account.t()} | {:error, :not_found}
  def get(id) do
    subquery = from(t in Trader, order_by: [asc: t.id])
    query = from(a in Account, where: a.id == ^id, order_by: [asc: a.id], preload: [traders: ^subquery])

    case Repo.one(query) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @spec get_all() :: [Account.t()]
  def get_all do
    subquery = from(t in Trader, order_by: [asc: t.id])
    query = from(a in Account, order_by: [asc: a.id], preload: [traders: ^subquery])

    Repo.all(query)
  end

  @spec create(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create(params) do
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  @spec update(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def update(account, params) do
    account
    |> Account.changeset(params)
    |> Repo.update()
  end

  @spec delete(Account.t()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def delete(account) do
    Repo.delete(account)
  end

  @spec create_trader(Account.t(), map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_trader(account, trader_params) do
    account
    |> Ecto.build_assoc(:traders)
    |> Trader.changeset(trader_params)
    |> Repo.insert()
  end

  @spec update_trader(Trader.t(), map()) :: {:ok, Trader.t()} | {:error, Ecto.Changeset.t()}
  def update_trader(trader, params) do
    trader
    |> Trader.changeset(params)
    |> Repo.update()
  end

  @spec delete_trader(Trader.t()) :: {:ok, Trader.t()} | {:error, Ecto.Changeset.t()}
  def delete_trader(trader) do
    Repo.delete(trader)
  end

  @spec create_event(Trader.t(), map()) :: {:ok, Trader.t()} | {:error, Ecto.Changeset.t()}
  def create_event(trader, event_params) do
    trader
    |> Ecto.build_assoc(:events)
    |> Event.changeset(event_params)
    |> Repo.insert()
  end

  @spec get_last_events(Trader.t()) :: [Event.t()]
  @spec get_last_events(Trader.t(), list(atom()) | :all) :: [Event.t()]
  @spec get_last_events(Trader.t(), list(atom()) | :all, non_neg_integer()) :: [Event.t()]
  def get_last_events(trader, types \\ :all, limit \\ 100) do
    where_types =
      if types != :all,
        do: dynamic([e], e.type in ^types),
        else: true

    Event
    |> where([e], e.trader_id == ^trader.id)
    |> where([e], ^where_types)
    |> order_by([e], desc: e.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @spec get_graph_data(Trader.t()) :: list(list())
  @spec get_graph_data(Trader.t(), :last_two_hours | :last_two_days | :last_month) :: list(list())
  def get_graph_data(trader, timeframe \\ :last_two_hours) do
    {aggregator, interval} =
      case timeframe do
        :last_two_hours -> {"minute", "'2' HOUR"}
        :last_two_days -> {"hour", "'2' DAY"}
        :last_month -> {"day", "'30' DAY"}
      end

    {:ok, %{rows: rows}} =
      Ecto.Adapters.SQL.query(
        Repo,
        "SELECT
          date_trunc($1, inserted_at) AS datetime,
          SUM(CASE WHEN type = 'success' THEN 1 ELSE 0 END) AS count
        FROM events
        WHERE trader_id = $2
          AND inserted_at >  TIMEZONE('utc', NOW()) - INTERVAL #{interval}
        GROUP BY date_trunc($1, inserted_at)
        ORDER BY date_trunc($1, inserted_at) DESC",
        [aggregator, trader.id]
      )

    rows
  end
end
