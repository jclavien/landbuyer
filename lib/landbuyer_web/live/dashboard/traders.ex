defmodule LandbuyerWeb.Live.Dashboard.Traders do
  @moduledoc false

  use LandbuyerWeb, :html

  alias Landbuyer.Schemas.Trader
  alias LandbuyerWeb.Live.Dashboard.TradersGraph

  attr(:account, :map, required: true)

  def traders_list(assigns) do
    ~H"""
    <h1 class="font-bold pb-4">
      <%= @account.label %>
    </h1>

    <section
      :for={trader <- @account.traders}
      class={[
        "mb-3 text-sm border bg-black/20 transition-all",
        if(trader.state == :active, do: "border-green/50 shadow-xl shadow-green/20", else: "border-gray-700")
      ]}
    >
      <.header trader={trader} account_id={@account.id} />
      <.options trader={trader} />
      <.live_component module={TradersGraph} id={trader.id} trader={trader} />
    </section>

    <.button phx-click="toggle_form_trader" theme={:secondary}>
      Ajouter un trader
    </.button>
    """
  end

  attr(:edit, :boolean, required: true)
  attr(:changeset, :map, required: true)

  def traders_create(assigns) do
    ~H"""
    <div class="flex justify-between items-center gap-4 pb-4">
      <h2 :if={@edit} class="font-bold">Modifier un trader</h2>
      <h2 :if={not @edit} class="font-bold">Ajouter un trader</h2>
      <.button theme={:ghost} only_icon={true} phx-click="toggle_form_trader">
        &times;
      </.button>
    </div>

    <.form :let={f} for={@changeset} phx-submit={if(@edit, do: "update_trader", else: "create_trader")} class="flex flex-col">
      <.input :if={@edit} type="hidden" field={{f, :id}} />
      <.input type="hidden" field={{f, :state}} />
      <.input type="select" field={{f, :strategy}} options={Trader.strategies()} label="Stratégie" />
      <.input field={{f, :rate_ms}} label="Interval (en millisecondes)" placeholder="ex. 1000" />

      <h3>Instrument</h3>
      <.inputs_for :let={f_instrument} field={f[:instrument]}>
        <div class="grid grid-cols-2 gap-x-4">
          <.input field={{f_instrument, :currency_pair}} label="Pair de devise" placeholder="ex. CHF_USD" />
          <.input field={{f_instrument, :round_decimal}} label="Nombre de décimales" placeholder="ex. 4" />
        </div>
      </.inputs_for>

      <h3>Options</h3>
      <.inputs_for :let={f_options} field={f[:options]}>
        <div class="grid grid-cols-2 gap-x-4">
          <.input field={{f_options, :distance_on_take_profit}} label="Take profit" placeholder="ex. 10" />
          <.input field={{f_options, :distance_on_stop_loss}} label="Stop loss" placeholder="ex. 20" />
          <.input field={{f_options, :distance_between_position}} label="Dist. entre positions" placeholder="ex. 1" />
          <.input field={{f_options, :position_amount}} label="Montant positions" placeholder="ex. 20" />
          <.input field={{f_options, :max_order}} label="Maximum d'ordres" placeholder="ex. 10" />
        </div>
      </.inputs_for>

      <.button :if={@edit}>Modifier le trader</.button>
      <.button :if={not @edit}>Ajouter le trader</.button>
    </.form>
    """
  end

  attr(:events, :list, required: true)

  def traders_last_event(assigns) do
    ~H"""
    <div class="flex justify-between items-center gap-4 pb-4">
      <h2 class="font-bold">Derniers événements</h2>
      <.button theme={:ghost} only_icon={true} phx-click="toggle_last_events">
        &times;
      </.button>
    </div>

    <div class="space-y-2">
      <section :for={event <- @events} class="hover:bg-gray-700">
        <header class="flex justify-between">
          <h1 class="flex gap-2">
            <span class="opacity-50">#<%= event.id %></span>
            <span><%= event.type %></span>
          </h1>
          <span class="opacity-50 text-sm">
            <%= NaiveDateTime.to_string(event.inserted_at) %>
          </span>
        </header>

        <div :if={not Enum.empty?(event.message)} class="pl-4">
          <div :for={{key, value} <- event.message} class="grid grid-cols-2">
            <span class="opacity-50"><%= key %></span>
            <span><%= value %></span>
          </div>
        </div>
      </section>
    </div>
    """
  end

  attr(:account_id, :integer, required: true)
  attr(:trader, :map, required: true)

  defp header(assigns) do
    ~H"""
    <.modal
      id={"modal-#{@trader.id}"}
      on_confirm={JS.push("delete_trader", value: %{id: @trader.id}) |> hide_modal("modal-#{@trader.id}")}
    >
      Confirmation de suppression
      <:confirm>
        <.button theme={:error}>
          Supprimer
        </.button>
      </:confirm>
      <:cancel>
        <.button theme={:secondary}>
          Annuler
        </.button>
      </:cancel>
    </.modal>

    <header class="relative p-4 border-b border-gray-700">
      <div class="flex gap-5 items-baseline">
        <h2 class="flex gap-2 items-center text-base">
          <div :if={@trader.state == :active} class="relative w-3 h-3">
            <div class="absolute inset-0 rounded-full bg-green"></div>
            <div class="absolute -inset-1 rounded-full bg-green/40 motion-safe:animate-ping"></div>
          </div>
          <div :if={@trader.state == :paused} class="w-3 h-3 rounded-full bg-gray-200"></div>
          <%= "Trader A#{@account_id}/T#{@trader.id}" %>
        </h2>

        <span :if={@trader.state == :active} class="opacity-50">
          Actif
        </span>
        <span :if={@trader.state == :paused} class="opacity-50">
          En pause
        </span>
      </div>

      <div class="absolute top-0 right-0 bottom-0 flex items-center gap-2 p-2">
        <.button
          :if={@trader.state == :active}
          phx-click="toggle_trader_state"
          phx-value-id={@trader.id}
          phx-throttle="1000"
          theme={:secondary}
          class="grid place-content-center h-8"
        >
          Pause
        </.button>
        <.button
          :if={@trader.state == :paused}
          phx-click="toggle_trader_state"
          phx-value-id={@trader.id}
          phx-throttle="1000"
          theme={:primary}
          class="grid place-content-center h-8"
        >
          Start
        </.button>
        <.button
          disabled={@trader.state != :paused}
          phx-click="toggle_form_trader"
          phx-value-id={@trader.id}
          theme={:secondary}
          class="grid place-content-center h-8"
        >
          Modifier
        </.button>
        <.button
          disabled={@trader.state != :paused}
          phx-click={show_modal("modal-#{@trader.id}")}
          theme={:error}
          class="grid place-content-center text-xl w-8 h-8"
        >
          &times;
        </.button>
      </div>
    </header>
    """
  end

  attr(:trader, :map, required: true)

  defp options(assigns) do
    ~H"""
    <div class="grid grid-cols-5 p-4 border-b border-gray-700">
      <.label_value label="Stratégie" value={Trader.strategy_name(@trader.strategy)} />
      <.label_value label="Interval" value={Landbuyer.Format.integer(@trader.rate_ms)} unit="ms" />
      <.label_value
        label="Instrument"
        value={@trader.instrument.currency_pair}
        unit={"(#{@trader.instrument.round_decimal} décimales)"}
      />
    </div>

    <div class="grid grid-cols-5 p-4 border-b border-gray-700">
      <.label_value label="Take profit" value={@trader.options.distance_on_take_profit} unit="pips" />
      <.label_value label="Stop loss" value={@trader.options.distance_on_stop_loss} unit="pips" />
      <.label_value label="Dist. entre positions" value={@trader.options.distance_between_position} unit="pips" />
      <.label_value label="Montant des positions" value={@trader.options.position_amount} unit="unités" />
      <.label_value label="Maximum d'ordres" value={@trader.options.max_order} unit="x2" />
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:unit, :string, default: nil)
  attr(:class, :string, default: "")

  defp label_value(assigns) do
    ~H"""
    <div class={["flex flex-col opacity-80", @class]}>
      <span class="font-bold">
        <%= @label %>
      </span>
      <span class="flex items-baseline gap-1">
        <span class="text-base whitespace-nowrap overflow-hidden">
          <%= @value %>
        </span>
        <span :if={@unit} class="text-sm opacity-50">
          <%= @unit %>
        </span>
      </span>
    </div>
    """
  end
end
