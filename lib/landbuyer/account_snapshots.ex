defmodule Landbuyer.AccountSnapshots do
  @moduledoc """
  Contexte pour gérer les snapshots de NAV des comptes.
  """

  import Ecto.Query, warn: false

  alias Landbuyer.AccountSnapshots.AccountSnapshot
  alias Landbuyer.Repo

  @doc """
  Renvoie tous les snapshots de NAV pour un compte donné, triés du plus ancien au plus récent.
  """
  def list_snapshots(account_id) do
    Repo.all(from(s in AccountSnapshot, where: s.account_id == ^account_id, order_by: [asc: s.inserted_at]))
  end
end
