defmodule Paradise.Components.StackSize do
  @moduledoc """
  The amount of items that will occupy a single inventory slot.
  """
  use ECSx.Component,
    value: :integer
end
