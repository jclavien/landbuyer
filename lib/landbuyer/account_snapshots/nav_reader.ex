defmodule Landbuyer.AccountSnapshots.NavReader do
  @moduledoc false
  import Ecto.Query, warn: false

  alias Landbuyer.AccountSnapshots.AccountSnapshot
  alias Landbuyer.Repo

  def get_latest_nav(account_id) do
    Repo.one(
      from s in AccountSnapshot,
        where: s.account_id == ^account_id,
        order_by: [desc: s.inserted_at],
        limit: 1
    )
  end

  def list_nav_points(account_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    base_query =
      from(s in AccountSnapshot,
        where: s.account_id == ^account_id,
        order_by: [asc: s.inserted_at]
      )

    query =
      case limit do
        :infinity ->
          # pas de limite
          base_query

        n when is_integer(n) ->
          from(s in base_query, limit: ^n)
      end

    Repo.all(query)
  end
end
