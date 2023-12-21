defmodule Paradise.Systems.ConsumeEnergy do
  @moduledoc """
  Documentation for ConsumeEnergy system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, energy} <- Components.Energy.get_all() do
      energy_x = velocity_to_energy(Components.XVelocity.get(entity))
      energy_y = velocity_to_energy(Components.YVelocity.get(entity))
      new_energy = energy - Enum.min([1, energy_x + energy_y])

      if new_energy > -1 do
        Components.Energy.update(entity, new_energy)
      else
        Components.Energy.update(entity, 0)
        Components.XVelocity.update(entity, 0)
        Components.YVelocity.update(entity, 0)
      end

      maybe_set_cooldown(entity)
    end
  end

  defp velocity_to_energy(0), do: 0
  defp velocity_to_energy(_), do: 1

  defp maybe_set_cooldown(entity) do
    unless Components.EnergyCooldown.exists?(entity) do
      now = DateTime.utc_now()
      cooldown_until = DateTime.add(now, 3, :second)
      Components.EnergyCooldown.add(entity, cooldown_until)
    end
  end
end
