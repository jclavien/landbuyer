defmodule LandbuyerWeb.Live.Dashboard.TradersGraph do
  @moduledoc """
  Trader graph live component.
  """

  use LandbuyerWeb, :live_component

  @timesframes [
    {:last_two_hours, "2 heures"},
    {:last_two_days, "2 jours"},
    {:last_month, "30 jours"}
  ]

  def mount(socket) do
    socket =
      socket
      |> assign(timeframe: :last_two_hours)
      |> assign(timeframes: @timesframes)

    {:ok, socket}
  end

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

        <.button phx-click="toggle_last_events" phx-value-id={@trader.id} theme={:secondary} class="grid place-content-center h-8">
          Afficher les derniers événements
        </.button>
      </div>

      <div class="py-4 px-3.5 pt-0 mt-4">
        <%= @graph %>
      </div>
    </div>
    """
  end

  def handle_event("update_timeframe", %{"timeframe" => timeframe}, socket) do
    socket =
      socket
      |> assign(timeframe: String.to_existing_atom(timeframe))
      |> load_graph()

    {:noreply, socket}
  end

  defp load_graph(%{assigns: %{trader: %{strategy: :landbuyer_origin}} = assigns} = socket) do
    # |> SparklineSvg.show_dots(class: "fill-green", radius: 0.2)
    # |> SparklineSvg.add_marker([marker3, marker4], class: "fill-yellow/40 stroke-none")

    graph =
      assigns.trader
      |> Landbuyer.Accounts.get_graph_data(assigns.timeframe)
      |> Enum.map(fn [datetime, count] -> {datetime, count} end)
      |> SparklineSvg.new(width: 100, height: 6, padding: 0.1, smoothing: 0)
      |> SparklineSvg.show_line(class: "stroke-green stroke-[0.08px] fill-transparent")
      |> SparklineSvg.show_area(class: "fill-green/10")
      |> SparklineSvg.to_svg()
      |> then(fn
        {:ok, svg} -> {:safe, svg}
        {:error, reason} -> Atom.to_string(reason)
      end)

    assign(socket, graph: graph)
  end

  defp load_graph(socket) do
    assign(socket, graph: nil)
  end
end
