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
          distance_on_take_profit: float() | nil,
          distance_between_position: float() | nil,
          distance_on_stop_loss: float() | nil,
          position_amount: integer() | nil,
          max_order: integer() | nil
        }
  embedded_schema do
    field(:distance_on_take_profit, :float)
    field(:distance_between_position, :float)
    field(:distance_on_stop_loss, :float)
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
