defmodule LandbuyerWeb.Live.Dashboard.Accounts do
  @moduledoc false
  use LandbuyerWeb, :html

  attr(:accounts, :map, required: true)
  attr(:active_account, :map)

  def accounts_list(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-3">
      <h1 class="text-2xl font-bold text-slate-100">Accounts</h1>
       <.icon_button click="toggle_form_account" label="Add account" d="M12 4v16m8-8H4" />
    </div>

    <div :for={account <- @accounts} class="relative mb-3 text-sm">
      <!-- suppression du modal Delete Account pour éviter le custom element -->
      <%!--
      <.modal
        id={"account-modal-#{account.id}"}
        on_confirm={JS.push("delete_account", value: %{id: account.id})
                    |> hide_modal("account-modal-#{account.id}")}>
        Are you sure?
        <:confirm>
          <.button theme={:error}>Delete</.button>
        </:confirm>
        <:cancel>
          <.button theme={:secondary}>Cancel</.button>
        </:cancel>
      </.modal>

      <div class="absolute top-2 right-2">
        <.icon_button_sm click={show_modal("account-modal-#{account.id}")}
                         label="Delete account"
                         d="M6 18L18 6M6 6l12 12" />
      </div>
      --%>
      
    <!-- lien vers le détail du compte -->
      <.link
        patch={~p"/account/#{account.id}"}
        class={[
          "block p-3 space-y-2 transition-all rounded-lg duration-300 w-full",
          if(@active_account && @active_account.id == account.id,
            do: "bg-slate-800 hover:bg-slate-800/60 w-[calc(100%+0.75rem)]",
            else: "bg-slate-600 hover:bg-slate-600/60"
          )
        ]}
      >
        <div class="text-lg font-bold">{account.label}</div>
        
        <div class="text-xs text-slate-400">Account ID: {account.id}</div>
        
        <%= if latest = Landbuyer.AccountSnapshots.NavReader.get_latest_nav(account.id) do %>
          <div class="text-2xl font-sans font-bold text-slate-100">
            NAV : {latest.nav}
          </div>
        <% else %>
          <div class="text-sm text-slate-400 italic">(pas encore de NAV)</div>
        <% end %>
      </.link>
    </div>
    """
  end

  attr(:changeset, :map, required: true)

  def accounts_create(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <h1 class="text-xl font-bold tracking-wide text-slate-100">
        Add account
      </h1>
       <.icon_button click="toggle_form_account" label="Back" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
    </div>

    <.form :let={f} for={@changeset} phx-submit="create_account" class="flex flex-col gap-4">
      <.input field={{f, :label}} label="Account name" placeholder="" />
      <.input field={{f, :oanda_id}} label="Oanda ID" placeholder="ex. xxx-xxx-xxxxxx-xxx" />
      <.input field={{f, :hostname}} label="Service URL" placeholder="ex. api-fxpractice.oanda.com" />
      <.input field={{f, :token}} label="Access key" />
      <div class="flex justify-end">
        <.icon_button type="submit" label="Add account" d="M12 4.5v15m7.5-7.5h-15" />
      </div>
    </.form>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:class, :string, default: "")

  defp label_value(assigns) do
    ~H"""
    <div class={["flex flex-col opacity-80", @class]}>
      <span class="font-bold">
        {@label}
      </span>
      
      <span class="whitespace-nowrap overflow-hidden">
        {@value}
      </span>
    </div>
    """
  end
end
