defmodule LandbuyerWeb.Live.Dashboard do
  @moduledoc """
  Main view.
  """

  use LandbuyerWeb, :live_view

  import LandbuyerWeb.Components.Navbar

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Landbuyer")}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.navbar />

    <section>
      Main
    </section>
    """
  end
end
