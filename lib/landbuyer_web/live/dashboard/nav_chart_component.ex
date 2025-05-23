defmodule LandbuyerWeb.Live.Dashboard.NavChartComponent do
  @moduledoc false
  use Phoenix.LiveComponent

  alias Landbuyer.AccountSnapshots

  @refresh_interval 30_000

  def mount(socket) do
    if connected?(socket), do: Process.send_after(self(), :refresh_nav, @refresh_interval)
    {:ok, assign(socket, :points, [])}
  end

  def update(%{account_id: account_id} = assigns, socket) do
    socket = assign(socket, assigns)
    # on précharge les points une fois à l’update initiale
    points = load_points(account_id)
    {:ok, assign(socket, :points, points)}
  end

  def handle_info(:refresh_nav, socket) do
    points = load_points(socket.assigns.account_id)
    # on reprogramme le refresh
    Process.send_after(self(), :refresh_nav, @refresh_interval)
    {:noreply, assign(socket, :points, points)}
  end

  defp load_points(account_id) do
    account_id
    |> AccountSnapshots.list_snapshots()
    |> Enum.map(fn %{inserted_at: dt, nav: nav} ->
      %{
        inserted_at: NaiveDateTime.to_iso8601(dt) <> "Z",
        nav: Decimal.to_float(nav)
      }
    end)
  end

  def render(assigns) do
    ~H"""
    <div id={"nav-chart-#{@id}"} phx-update="ignore" phx-hook="NavChart" data-points={Jason.encode!(@points)} style="height:400px;">
      <canvas></canvas>
    </div>
    """
  end
end
