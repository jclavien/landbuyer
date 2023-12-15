defmodule LandbuyerWeb.Live.Dashboard.Accounts do
  @moduledoc false

  use LandbuyerWeb, :html

  attr(:accounts, :map, required: true)

  @spec accounts_list(map()) :: Phoenix.LiveView.Rendered.t()
  def accounts_list(assigns) do
    ~H"""
    <h1 class="font-bold pb-4">
      Comptes
    </h1>

    <div :for={account <- @accounts} class="relative mb-3 text-sm">
      <.modal id={"confirm-modal-#{account.id}"} on_confirm={JS.push("delete_account", value: %{id: account.id})}>
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

      <button
        :if={length(account.traders) == 0}
        phx-click={show_modal("confirm-modal-#{account.id}")}
        phx-value-id={account.id}
        class="absolute grid place-content-center text-xl top-2 right-2 w-5 h-5 border border-black/80 bg-red/60 text-black/80 hover:bg-red transition-all"
      >
        &times;
      </button>
      <.link
        patch={~p"/account/#{account.id}"}
        class="block p-3 space-y-2 border border-gray-800 bg-black/20 hover:bg-black/30 transition-all"
      >
        <div class="text-base">
          <%= account.label %>
        </div>
        <div class="flex justify-between">
          <.label_value label="URL du service" value={account.hostname} />
          <.label_value label="Traders" value={length(account.traders)} class="text-right" />
        </div>
        <.label_value label="ID de compte" value={account.oanda_id} />
        <.label_value label="Jeton d'accès" value={account.token} />
      </.link>
    </div>

    <.button phx-click="toggle_form_account" theme={:secondary} class="w-full">
      Ajouter un compte
    </.button>
    """
  end

  attr(:changeset, :map, required: true)

  @spec accounts_create(map()) :: Phoenix.LiveView.Rendered.t()
  def accounts_create(assigns) do
    ~H"""
    <div class="flex items-center gap-4 pb-4">
      <.button theme={:ghost} only_icon={true} phx-click="toggle_form_account">
        &lsaquo;
      </.button>
      <h1 class="font-bold">
        Ajouter un compte
      </h1>
    </div>

    <.form :let={f} for={@changeset} phx-submit="create_account" class="flex flex-col">
      <.input field={{f, :label}} label="Nom du compte" placeholder="ex. Compte de test" />
      <.input field={{f, :oanda_id}} label="ID du compte Oanda" placeholder="ex. xxx-xxx-xxxxxx-xxx" />
      <.input field={{f, :hostname}} label="URL du service" placeholder="ex. api-fxpractice.oanda.com" />
      <.input field={{f, :token}} label="Jeton d'accès" />
      <.button>
        Ajouter le compte
      </.button>
    </.form>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:class, :string, default: "")

  @spec label_value(map()) :: Phoenix.LiveView.Rendered.t()
  defp label_value(assigns) do
    ~H"""
    <div class={["flex flex-col opacity-80", @class]}>
      <span class="font-bold">
        <%= @label %>
      </span>
      <span class="whitespace-nowrap overflow-hidden">
        <%= @value %>
      </span>
    </div>
    """
  end
end
