defmodule Landbuyer.Schemas.TraderOptions do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Landbuyer.Schemas.TraderOptions

  @fields [
    :distance_on_take_profit,
    :distance_between_position,
    :distance_on_stop_loss,
    :position_amount,
    :max_order
  ]

  @type t() :: %TraderOptions{
          distance_on_take_profit: integer() | nil,
          distance_between_position: integer() | nil,
          distance_on_stop_loss: integer() | nil,
          position_amount: integer() | nil,
          max_order: integer() | nil
        }
  embedded_schema do
    field(:distance_on_take_profit, :integer)
    field(:distance_between_position, :integer)
    field(:distance_on_stop_loss, :integer)
    field(:position_amount, :integer)
    field(:max_order, :integer)
  end

  @spec changeset(TraderOptions.t(), map()) :: Ecto.Changeset.t()
  def changeset(trader_options, params \\ %{}) do
    trader_options
    |> cast(params, @fields)
    |> validate_required(@fields, message: "Champ requis")
  end
end
