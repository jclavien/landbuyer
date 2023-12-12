defmodule LandbuyerWeb.Plugs.Auth do
  @moduledoc """
  Plug to authenticate admin users.
  """

  def init(options), do: options

  def call(conn, _opts) do
    username = Application.fetch_env!(:landbuyer, :username)
    password = Application.fetch_env!(:landbuyer, :password)

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
