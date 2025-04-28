defmodule LandbuyerWeb.Live.Dashboard.Layout do
  @moduledoc false

  use LandbuyerWeb, :html

  def layout_header(assigns) do
    ~H"""
    <header class="flex items-center h-14 px-4 border-b bg-slate-700 text-slate-100 border-slate-700">
      <.link patch={~p"/"} class="flex items-center gap-2">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="w-8 h-8 mr-2 text-blue-300"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M15.59 14.37a6 6 0 0 1-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 0 0 6.16-12.12A14.98 14.98 0 0 0 9.631 8.41m5.96 5.96a14.926 14.926 0 0 1-5.841 2.58m-.119-8.54a6 6 0 0 0-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 0 0-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 0 1-2.448-2.448 14.9 14.9 0 0 1 .06-.312m-2.24 2.39a4.493 4.493 0 0 0-1.757 4.306 4.493 4.493 0 0 0 4.306-1.758M16.5 9a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Z"
          />
        </svg>
        
        <h1 class="font-bold leading-tight">
          <div class="text-3xl uppercase">LANDBUYER</div>
          
          <div class="text-sm text-slate-200">v3.2</div>
        </h1>
      </.link>
    </header>
    """
  end

  attr(:flash, :map, required: true)
  attr(:account_count, :integer, required: true)
  attr(:trader_count, :integer, required: true)
  attr(:active_trader_count, :integer, required: true)

  def layout_footer(assigns) do
    ~H"""
    <footer class="relative flex items-center px-4 h-14 border-t bg-slate-800 text-slate-100 border-slate-800">
      <div class="flex items-center gap-6 text-sm">
        <span>
          <strong>{@account_count}</strong> comptes
        </span>
        
        <span>
          <strong>{@trader_count}</strong> traders
        </span>
        
        <span :if={@active_trader_count > 0} class="text-green">
          <strong>{@active_trader_count}</strong> traders actifs
        </span>
      </div>
      
      <div class="absolute flex gap-3 top-3 right-3 bottom-3">
        <.flash_group flash={@flash} />
      </div>
    </footer>
    """
  end
end
