defmodule Paradise.Systems.RestoreEnergy do
  @moduledoc """
  Documentation for RestoreEnergy system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, energy} <- Components.EnergyLevel.get_all() do
      unless Components.EnergyCooldown.exists?(entity) do
        energy_capacity = Components.EnergyCapacity.get(entity)

        if energy < energy_capacity do
          new_energy = Enum.min([energy_capacity, energy + 10])
          Components.EnergyLevel.update(entity, new_energy)
        end
      end
    end
  end
end
