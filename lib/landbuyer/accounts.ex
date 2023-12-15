defmodule Landbuyer.Accounts do
  @moduledoc false

  import Ecto.Query

  alias Landbuyer.Repo
  alias Landbuyer.Schemas.Account
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
  def get_all() do
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
end
