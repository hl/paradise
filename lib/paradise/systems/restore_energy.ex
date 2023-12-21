defmodule Paradise.Systems.RestoreEnergy do
  @moduledoc """
  Documentation for RestoreEnergy system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, energy} <- Components.Energy.get_all() do
      unless Components.EnergyCooldown.exists?(entity) do
        max_energy = Components.EnergyCapacity.get(entity)

        if energy < max_energy do
          new_energy = Enum.min([max_energy, energy + 10])
          Components.Energy.update(entity, new_energy)
        end
      end
    end
  end
end
