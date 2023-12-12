defmodule LandbuyerWeb.Components.Navbar do
  @moduledoc """
  """

  use LandbuyerWeb, :html

  @spec navbar(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
  def navbar(assigns) do
    ~H"""
    <header class="bg-white text-slate-900 border-b md:border-none py-3 px-2 shadow-md flex justify-between print:hidden">
      Header
    </header>
    """
  end
end
