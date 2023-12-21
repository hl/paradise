defmodule Paradise.Manager do
  @moduledoc """
  ECSx manager.
  """
  use ECSx.Manager

  alias Paradise.Components
  alias Paradise.Systems

  def setup do
    # Seed persistent components only for the first server start
    # (This will not be run on subsequent app restarts)
    :ok
  end

  def startup do
    # Load ephemeral components during first server start and again
    # on every subsequent app restart
    :ok
  end

  # Declare all valid Component types
  def components do
    [
      Components.Amount,
      Components.AstronautSpawned,
      Components.Collectable,
      Components.Common,
      Components.Currency,
      Components.Description,
      Components.Energy,
      Components.EnergyCapacity,
      Components.EnergyCooldown,
      Components.Epic,
      Components.Harvestable,
      Components.ImageFile,
      Components.Inventory,
      Components.InventoryItem,
      Components.Level,
      Components.Metal,
      Components.Mineral,
      Components.Rare,
      Components.SlotsAvailable,
      Components.SlotsCapacity,
      Components.StackSize,
      Components.Substance,
      Components.XPosition,
      Components.XVelocity,
      Components.YPosition,
      Components.YVelocity
    ]
  end

  # Declare all Systems to run
  def systems do
    [
      Systems.ClientEventHandler,
      Systems.ConsumeEnergy,
      Systems.MoveEntity,
      Systems.CooldownExpiration,
      Systems.RestoreEnergy
    ]
  end
end
