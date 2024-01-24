defmodule LandbuyerWeb.Live.Dashboard.TradersGraph do
  @moduledoc """
  Trader graph live component.
  """

  use LandbuyerWeb, :live_component

  @graph_options [
    width: 100,
    height: 6,
    padding: 0.5,
    show_dot: false,
    dot_radius: 0.1,
    dot_color: "rgb(255, 255, 255)",
    line_color: "rgba(166, 218, 149)",
    line_width: 0.05,
    line_smoothing: 0
  ]

  @spec mount(map()) :: {:ok, map()}
  def mount(socket) do
    socket =
      socket
      |> assign(timeframe: :last_hour)
      |> assign(timeframes: [{:last_hour, "heure"}, {:last_day, "jour"}, {:last_week, "semaine"}])

    {:ok, socket}
  end

  @spec update(map(), map()) :: {:ok, map()}
  def update(%{trader: trader}, %{assigns: assigns} = socket) do
    if Map.has_key?(assigns, :trader) and assigns.trader == trader do
      {:ok, socket}
    else
      socket =
        socket
        |> assign(trader: trader)
        |> load_graph()

      {:ok, socket}
    end
  end

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <div class="p-4 pb-0 mb-4 w-full flex justify-between">
        <div>
          <div :if={@graph} class="flex gap-4">
            <h2>Visualisation</h2>
            <div class="flex gap-2">
              <button
                :for={{timeframe, label} <- @timeframes}
                phx-click="update_timeframe"
                phx-value-timeframe={timeframe}
                phx-target={@myself}
                theme={:secondary}
                class={["opacity-60 hover:opacity-100", timeframe == @timeframe && "font-bold underline"]}
              >
                <%= label %>
              </button>
            </div>
          </div>

          <h2 :if={is_nil(@graph)} class="opacity-50">
            Visualisation non disponible
          </h2>
        </div>

        <.button
          phx-click="todo"
          phx-value-id={@trader.id}
          phx-target={@myself}
          theme={:secondary}
          class="grid place-content-center h-8"
        >
          Afficher les derniers événements
        </.button>
      </div>

      <div :if={@graph} class="py-4 px-3.5 pt-0 mt-4">
        <%= raw(@graph) %>
      </div>
    </div>
    """
  end

  @spec handle_event(String.t(), map(), map()) :: {:noreply, any()}
  def handle_event("update_timeframe", %{"timeframe" => timeframe}, socket) do
    socket =
      socket
      |> assign(timeframe: String.to_existing_atom(timeframe))
      |> load_graph()

    {:noreply, socket}
  end

  defp load_graph(%{assigns: %{trader: %{strategy: :landbuyer_origin}} = assigns} = socket) do
    data =
      assigns.trader
      |> Landbuyer.Accounts.get_graph_data(assigns.timeframe)
      |> Enum.map(fn [datetime, count] ->
        {seconds, _} = NaiveDateTime.to_gregorian_seconds(datetime)
        {seconds, count}
      end)

    graph =
      case SimpleCharts.Line.to_svg(data, @graph_options) do
        {:ok, graph} -> graph
        {:error, _reason} -> nil
      end

    assign(socket, graph: graph)
  end

  defp load_graph(socket) do
    assign(socket, graph: nil)
  end
end
