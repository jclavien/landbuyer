defmodule LandbuyerWeb.CoreComponents do
  # credo:disable-for-this-file

  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>

  JS commands may be passed to the `:on_cancel` and `on_confirm` attributes
  for the caller to react to each button press, for example:

      <.modal id="confirm" on_confirm={JS.push("delete")} on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:confirm>OK</:confirm>
        <:cancel>Cancel</:cancel>
      </.modal>
  """
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})
  attr(:on_confirm, JS, default: %JS{})

  slot(:inner_block, required: true)
  slot(:confirm)
  slot(:cancel)

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="hidden relative z-50">
      <div id={"#{@id}-bg"} class="fixed inset-0 transition-opacity bg-slate-100" aria-hidden="true" />
      <div
        class="overflow-y-auto fixed inset-0"
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex justify-center items-center min-h-full">
          <div class="p-4 w-full max-w-lg">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-mounted={@show && show_modal(@id)}
              phx-window-keydown={hide_modal(@on_cancel, @id)}
              phx-key="escape"
              phx-click-away={hide_modal(@on_cancel, @id)}
              class="hidden relative p-4 bg-slate-700 border-2 border-slate-700 shadow-lg transition"
            >
              <div id={"#{@id}-content"} class="flex flex-col gap-4 text-base">
                {render_slot(@inner_block)}
                <div :if={@confirm != [] or @cancel != []} class="flex gap-4 items-center">
                  <div :for={confirm <- @confirm} id={"#{@id}-confirm"} phx-click={@on_confirm} phx-disable-with>
                    {render_slot(confirm)}
                  </div>
                  
                  <div :for={cancel <- @cancel} phx-click={hide_modal(@on_cancel, @id)}>
                    {render_slot(cancel)}
                  </div>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
    <.flash
      id="client-error"
      kind={:neutral}
      phx-disconnected={show(".phx-client-error #client-error")}
      phx-connected={hide("#client-error")}
      hidden
    >
      Reconnection
    </.flash>

    <.flash
      id="server-error"
      kind={:neutral}
      phx-disconnected={show(".phx-server-error #server-error")}
      phx-connected={hide("#server-error")}
      hidden
    >
      Serveur indisponible
    </.flash>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, default: "flash", doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:kind, :atom, values: [:info, :error, :neutral], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "relative flex items-center p-2 pr-5 bg-slate-800 text-sm text-slate-200",
        @kind == :neutral && "border border-gray-200",
        @kind == :error && "border border-red text-red",
        @kind == :info && "border border-green text-green"
      ]}
      {@rest}
    >
      <p>
        {msg}
      </p>
      
      <button
        type="button"
        class={[
          "absolute cursor-pointer top-0 right-0 w-3 h-3",
          @kind == :neutral && "bg-slate-700",
          @kind == :error && "bg-red",
          @kind == :info && "bg-green"
        ]}
        aria-label="close"
      >
      </button>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr(:type, :string, default: nil)
  attr(:theme, :atom, default: :primary)
  attr(:only_icon, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(disabled form name value))

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 flex gap-3 rounded text-left transition-all",
        theme(@theme),
        only_icon(@only_icon),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp theme(:primary), do: "bg-slate-800 disabled:hover:bg-slate-800 hover:bg-slate-900 border-green text-green"

  defp theme(:secondary),
    do: "bg-slate-800 disabled:hover:bg-slate-800 hover:bg-slate-900 border-slate-500 text-slate-50"

  defp theme(:error), do: "bg-slate-800 disabled:hover:bg-slate-800 hover:bg-slate-900 border-red text-red"
  defp theme(:ghost), do: "text-slate-50 disabled:hover:text-slate-50 hover:text-white border-transparent"

  defp only_icon(false), do: "text-sm py-3 px-4"
  defp only_icon(true), do: "text-xl"

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr(:id, :any)
  attr(:name, :any)
  attr(:label, :string, default: nil)

  attr(:type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)
  )

  attr(:value, :any)
  attr(:field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}")
  attr(:errors, :list)
  attr(:checked, :boolean, doc: "the checked flag for checkbox inputs")
  attr(:prompt, :string, default: nil, doc: "the prompt for select inputs")
  attr(:options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2")
  attr(:multiple, :boolean, default: false, doc: "the multiple flag for select inputs")
  attr(:rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step style))
  slot(:inner_block)

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Phoenix.HTML.Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Phoenix.HTML.Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Phoenix.HTML.Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> prepare_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <label phx-feedback-for={@name} class="flex gap-4 items-center text-sm">
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={@id || @name}
        name={@name}
        value="true"
        checked={@checked}
        class="rounded border-slate-300 focus:border-blue-300"
        {@rest}
      /> {@label}
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      
      <select
        id={@id}
        name={@name}
        class={[
          "mt-0.5 block w-full border-2 p-1 placeholder:text-gray-500",
          "text-sm text-gray-900 bg-slate-300 focus:outline-none focus:ring-2",
          "phx-no-feedback:border-gray-800 phx-no-feedback:focus:border-gray-300",
          input_border(@errors)
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt}>{@prompt}</option>
         {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
       <.error errors={@errors} />
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
       <textarea
        id={@id || @name}
        name={@name}
        class={[
          "mt-0.5 block h-40 w-full border-2 p-2 placeholder:text-gray-50",
          "text-sm text-gray-900 bg-white focus:outline-none focus:ring-1",
          "phx-no-feedback:border-gray-100 phx-no-feedback:focus:border-gray-100",
          input_border(@errors)
        ]}
        {@rest}
      >
    <%= @value %></textarea> <.error errors={@errors} />
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}>{@label}</.label>
      
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          "mt-0.5 block w-full border-2 p-2 placeholder:text-gray-50",
          "text-sm text-gray-900 bg-white focus:outline-none focus:ring-1",
          "phx-no-feedback:border-gray-100 phx-no-feedback:focus:border-gray-100",
          input_border(@errors)
        ]}
        {@rest}
      /> <.error errors={@errors} />
    </div>
    """
  end

  defp input_border([] = _errors), do: "border-gray-100 focus:ring-gray-100"
  defp input_border([_ | _] = _errors), do: "border-red focus:border-red focus:ring-red"

  @doc """
  Renders a label.
  """
  attr(:for, :string, default: nil)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-base">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr(:errors, :list, required: true)

  def error(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 mt-0.5 text-xs min-h-[15px] text-red">
      <p :for={msg <- @errors}>
        {String.capitalize(msg)}
      </p>
    </div>
    """
  end

  # @doc """
  # Prepare the errors for a field from a keyword list of errors.
  # """
  defp prepare_errors(errors, field) when is_list(errors) do
    for {^field, {msg, _opts}} <- errors, do: msg
  end

  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector, time: 200, transition: {"", "opacity-0", "opacity-100"})
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 200, transition: {"", "opacity-100", "opacity-0"})
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-200", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end

  # @doc """
  # Squared button with icon
  attr(:type, :string, default: "button")
  attr(:click, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:d, :string, required: true)
  attr(:class, :string, default: "")

  def icon_button(assigns) do
    # Récupère la classe passée (ou "")
    user_class = assigns[:class] || ""

    # Si l'utilisateur a passé un "bg-…" on n'applique PAS le bg par défaut
    default_bg =
      if String.match?(user_class, ~r/(^|\s)bg-/), do: "", else: "bg-slate-800 hover:bg-slate-600"

    classes =
      [
        # squelette commun
        "grid place-content-center w-8 h-8 rounded",
        # bg par défaut (ou vide)
        default_bg,
        # classes de l'appelant
        user_class
      ]
      # on vire les chaînes vides
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(" ")

    assigns = assign(assigns, :class, classes)

    ~H"""
    <button type="button" class={@class} aria-label={@label} phx-click={@click}>
      <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path d={@d} stroke-linecap="round" stroke-linejoin="round" stroke-width="2" />
      </svg>
    </button>
    """
  end

  @doc """
  Small icon button, 4x4 instead of 8x8.
  """
  attr(:click, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:d, :string, required: true)

  def icon_button_sm(assigns) do
    ~H"""
    <button
      type="button"
      phx-click={@click}
      class="grid place-content-center w-5 h-5 bg-slate-800 hover:bg-slate-600 rounded"
      aria-label={@label}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="w-4 h-4 text-red-400"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="3"
      >
        <path d={@d} stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </button>
    """
  end
end
