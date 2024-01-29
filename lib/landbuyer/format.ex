defmodule Landbuyer.Format do
  @moduledoc """
  Generalist module for formatting data.
  """

  @doc """
  Format an integer to a string with thousand separator.

  ## Examples

      iex> Landbuyer.Format.integer(123456789)
      "123 456 789"

      iex> Landbuyer.Format.integer(123456789, ",")
      "123,456,789"

  """
  @spec integer(integer(), String.t()) :: String.t()
  def integer(integer, separator \\ " ") do
    integer
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(separator)
    |> String.reverse()
  end
end
