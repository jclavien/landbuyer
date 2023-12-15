defmodule LandbuyerWeb.Live.Dashboard do
  @moduledoc """
  Main view.
  """

  use LandbuyerWeb, :live_view

  import LandbuyerWeb.Live.Dashboard.Accounts
  import LandbuyerWeb.Live.Dashboard.Layout
  import LandbuyerWeb.Live.Dashboard.Traders

  alias Landbuyer.Accounts
  alias Landbuyer.Schemas.Account
  alias Landbuyer.Schemas.Trader

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: "Landbuyer")
      |> default_assigns()
      |> assign(active_account: nil)
      |> assign(show_form_account: false)
      |> assign(account_changeset: default_account_changeset())
      |> assign(show_form_trader: false)
      |> assign(trader_edit: false)
      |> assign(trader_changeset: default_trader_changeset())

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"account" => account_id}, _uri, socket) do
    {:noreply, set_active_account(socket, account_id)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, active_account: nil)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="h-screen">
      <.layout_header />

      <div class="flex h-[calc(100%-7rem)] overflow-hidden">
        <div class="w-96 p-4 border-r bg-gray-900 border-gray-700 overflow-y-auto">
          <.accounts_list :if={not @show_form_account} accounts={@accounts} />
          <.accounts_create :if={@show_form_account} changeset={@account_changeset} />
        </div>

        <div class="relative flex flex-1 flex-col p-4 w-full overflow-y-auto overflow-x-hidden">
          <div :if={@active_account}>
            <.traders_list account={@active_account} />
          </div>
          <div class={[
            "fixed top-14 bottom-14 w-96 transition-all",
            "border-l bg-gray-900 border-gray-700 shadow-xl",
            @show_form_trader && "right-0",
            not @show_form_trader && "-right-96"
          ]}>
            <div :if={@show_form_trader} phx-click-away="toggle_form_trader" class="h-full p-4 overflow-y-auto">
              <.traders_create changeset={@trader_changeset} edit={@trader_edit} />
            </div>
          </div>
        </div>
      </div>

      <.layout_footer flash={@flash} account_count={@account_count} trader_count={@trader_count} />
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_form_account", _params, socket) do
    {:noreply, assign(socket, show_form_account: not socket.assigns.show_form_account)}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_form_trader", %{"id" => trader_id}, socket) do
    trader_id = String.to_integer(trader_id)
    trader = Enum.find(socket.assigns.active_account.traders, fn t -> t.id == trader_id end)

    socket =
      socket
      |> assign(show_form_trader: not socket.assigns.show_form_trader)
      |> assign(trader_edit: true)
      |> assign(trader_changeset: Trader.changeset(trader, %{}))

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_form_trader", _params, socket) do
    socket =
      socket
      |> assign(show_form_trader: not socket.assigns.show_form_trader)
      |> assign(trader_edit: false)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("create_account", %{"account" => account}, socket) do
    case Accounts.create(account) do
      {:ok, account} ->
        socket =
          socket
          |> default_assigns()
          |> assign(show_form_account: false)
          |> assign(account_changeset: default_account_changeset())
          |> put_flash(:info, "Compte ajouté")
          |> push_patch(to: ~p"/account/#{account.id}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, account_changeset: changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_account", %{"id" => id}, socket) do
    account = Enum.find(socket.assigns.accounts, fn a -> a.id == id end)

    case Accounts.delete(account) do
      {:ok, _account} ->
        {:noreply, socket |> default_assigns() |> put_flash(:info, "Compte supprimé") |> push_patch(to: ~p"/")}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Erreur lors de la suppression du compte")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("create_trader", %{"trader" => trader}, socket) do
    account = socket.assigns.active_account

    case Accounts.create_trader(account, trader) do
      {:ok, _trader} ->
        socket =
          socket
          |> default_assigns()
          |> assign(show_form_trader: false)
          |> assign(trader_changeset: default_trader_changeset())
          |> put_flash(:info, "Trader ajouté")
          |> push_patch(to: ~p"/account/#{account.id}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, trader_changeset: changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update_trader", %{"trader" => params}, socket) do
    account = socket.assigns.active_account
    trader_id = String.to_integer(params["id"])
    trader = Enum.find(account.traders, fn t -> t.id == trader_id end)

    case Accounts.update_trader(trader, params) do
      {:ok, _trader} ->
        socket =
          socket
          |> default_assigns()
          |> assign(show_form_trader: false)
          |> assign(trader_changeset: default_trader_changeset())
          |> put_flash(:info, "Trader modifié")
          |> push_patch(to: ~p"/account/#{account.id}")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, trader_changeset: changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("toggle_trader_state", %{"id" => id}, socket) do
    trader_id = String.to_integer(id)
    trader = Enum.find(socket.assigns.active_account.traders, fn t -> t.id == trader_id end)
    new_state = if trader.state == :active, do: :paused, else: :active
    message = if trader.state == :active, do: "Trader mis en pause", else: "Trader démarré"

    if new_state == :active do
      # TODO:
      # - Start trader with Supervisor
      IO.inspect("Create worker")
    end

    if new_state == :paused do
      # TODO:
      # - Kill trader with Supervisor
      IO.inspect("Kill worker")
    end

    case Accounts.update_trader(trader, %{"state" => new_state}) do
      {:ok, _trader} ->
        socket =
          socket
          |> default_assigns()
          |> set_active_account(socket.assigns.active_account.id)
          |> put_flash(:info, message)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erreur lors du changement d'état du trader")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_trader", %{"id" => id}, socket) do
    account = socket.assigns.active_account
    trader = Enum.find(account.traders, fn t -> t.id == id end)

    case Accounts.delete_trader(trader) do
      {:ok, _trader} ->
        {:noreply,
         socket
         |> default_assigns()
         |> put_flash(:info, "Trader supprimé")
         |> push_patch(to: ~p"/account/#{account.id}")}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Erreur lors de la suppression du compte")}
    end
  end

  defp default_assigns(socket) do
    accounts = Accounts.get_all()
    account_count = length(accounts)
    trader_count = Enum.reduce(accounts, 0, fn a, sum -> sum + length(a.traders) end)

    socket
    |> assign(accounts: accounts)
    |> assign(account_count: account_count)
    |> assign(trader_count: trader_count)
  end

  defp set_active_account(socket, account_id) when is_binary(account_id) do
    set_active_account(socket, String.to_integer(account_id))
  end

  defp set_active_account(socket, account_id) do
    account = Enum.find(socket.assigns.accounts, fn account -> account.id == account_id end)
    assign(socket, active_account: account)
  end

  defp default_account_changeset() do
    Account.changeset(%Account{}, %{})
  end

  defp default_trader_changeset() do
    Trader.changeset(%Trader{}, %{"state" => :paused})
  end
end
