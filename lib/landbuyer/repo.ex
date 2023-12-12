defmodule Landbuyer.Repo do
  use Ecto.Repo,
    otp_app: :landbuyer,
    adapter: Ecto.Adapters.Postgres
end
