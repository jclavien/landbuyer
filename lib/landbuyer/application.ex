defmodule Landbuyer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LandbuyerWeb.Telemetry,
      # Start the Ecto repository
      Landbuyer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Landbuyer.PubSub},
      # Start Finch
      {Finch, name: Landbuyer.Finch},
      # Start the Endpoint (http/https)
      LandbuyerWeb.Endpoint
      # Start a worker by calling: Landbuyer.Worker.start_link(arg)
      # {Landbuyer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Landbuyer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    LandbuyerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
