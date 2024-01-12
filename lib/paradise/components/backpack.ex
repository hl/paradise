defmodule Paradise.Components.Backpack do
  @moduledoc """
  Represents the connection between two entities.

  Example:
    iex> Backpack.add(backpack_entity, astronaut_entity)
  """
  use ECSx.Component,
    value: :binary
end
