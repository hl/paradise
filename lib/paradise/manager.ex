defmodule Paradise.Manager do
  @moduledoc """
  ECSx manager.
  """
  use ECSx.Manager

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
      Paradise.Components.Playable,
      Paradise.Components.Backpack,
      Paradise.Components.Collectable,
      Paradise.Components.Currency,
      Paradise.Components.Description,
      Paradise.Components.Element,
      Paradise.Components.EnergyCapacity,
      Paradise.Components.EnergyCooldown,
      Paradise.Components.EnergyLevel,
      Paradise.Components.Harvestable,
      Paradise.Components.ImageFile,
      Paradise.Components.Inventory,
      Paradise.Components.InventoryItem,
      Paradise.Components.Location,
      Paradise.Components.Matter,
      Paradise.Components.OxygenCapacity,
      Paradise.Components.OxygenCooldown,
      Paradise.Components.OxygenCooldown,
      Paradise.Components.OxygenLevel,
      Paradise.Components.PlayerLevel,
      Paradise.Components.Quantity,
      Paradise.Components.Rarity,
      Paradise.Components.SlotsAvailable,
      Paradise.Components.SlotsCapacity,
      Paradise.Components.Spawned,
      Paradise.Components.StackSize,
      Paradise.Components.XPosition,
      Paradise.Components.XVelocity,
      Paradise.Components.YPosition,
      Paradise.Components.YVelocity
    ]
  end

  # Declare all Systems to run
  def systems do
    [
      Paradise.Systems.ClientEventHandler,
      Paradise.Systems.ConsumeOxygen,
      Paradise.Systems.ConsumeEnergy,
      Paradise.Systems.MoveEntity,
      Paradise.Systems.CooldownExpiration,
      Paradise.Systems.RestoreOxygen,
      Paradise.Systems.RestoreEnergy
    ]
  end
end
