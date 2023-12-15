defmodule LandbuyerWeb.Live.Dashboard.Layout do
  @moduledoc false

  use LandbuyerWeb, :html

  @spec layout_header(any()) :: Phoenix.LiveView.Rendered.t()
  def layout_header(assigns) do
    ~H"""
    <header class="flex items-center h-14 px-4 border-b bg-gray-950 border-gray-700">
      <.link patch={~p"/"}>
        <h1 class="font-bold text-xl">
          Landbuyer
        </h1>
      </.link>
    </header>
    """
  end

  attr(:flash, :map, required: true)
  attr(:account_count, :integer, required: true)
  attr(:trader_count, :integer, required: true)

  def layout_footer(assigns) do
    ~H"""
    <footer class="relative flex items-center px-4 h-14 border-t bg-gray-950 border-gray-700">
      <div class="flex items-center gap-6 text-sm">
        <span>
          <strong><%= @account_count %></strong> comptes
        </span>
        <span>
          <strong><%= @trader_count %></strong> traders
        </span>
      </div>

      <div class="absolute flex gap-3 top-3 right-3 bottom-3">
        <.flash_group flash={@flash} />
      </div>
    </footer>
    """
  end
end
