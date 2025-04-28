defmodule LandbuyerWeb.Live.Dashboard.NavChartComponent do
  @moduledoc false
  use Phoenix.LiveComponent

  alias Landbuyer.AccountSnapshots

  @refresh_interval 30_000

  @impl true
  def mount(socket) do
    if connected?(socket), do: Process.send_after(self(), :refresh_nav, @refresh_interval)

    {:ok, assign(socket, :points, [])}
  end

  @impl true
  def update(%{account_id: account_id} = assigns, socket) do
    socket = assign(socket, assigns)
    points = load_points(account_id)
    {:ok, assign(socket, :points, points)}
  end

  def handle_info(:refresh_nav, socket) do
    points = load_points(socket.assigns.account_id)
    # reprogrammation du timer à chaque rafraîchissement
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

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"nav-chart-#{@id}"}
      phx-update="ignore"
      phx-hook="NavChart"
      data-points={Jason.encode!(@points)}
      class="w-full max-w-7xl h-96"
    >
      <canvas class="w-full h-full"></canvas>
    </div>
    """
  end
end
