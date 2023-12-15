defmodule LandbuyerWeb.Router do
  use LandbuyerWeb, :router

  alias LandbuyerWeb.Plugs, as: Plugs

  pipeline(:browser) do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {LandbuyerWeb.Components.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  # Default empty live session
  # Only for redirecting to correct liveview
  scope("/", LandbuyerWeb.Live) do
    pipe_through([:browser, Plugs.Auth])

    live("/", Dashboard)
    live("/account/:account", Dashboard)
  end
end
