defmodule Paradise.Components.Matter do
  @moduledoc """
  Documentation for MatterMetal components.
  """
  use ECSx.Component, value: :atom

  def metal, do: :metal
  def mineral, do: :mineral
end
