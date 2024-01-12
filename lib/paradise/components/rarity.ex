defmodule Paradise.Components.Rarity do
  @moduledoc """
  Documentation for RarityCommon components.
  """
  use ECSx.Component, value: :atom

  def common, do: :common
  def uncommon, do: :uncommon
  def rare, do: :rare
  def epic, do: :epic
  def legendary, do: :legendary
end
