defmodule Paradise.Systems.RestoreOxygen do
  @moduledoc """
  Documentation for RestoreOxygen system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, oxygen} <- Components.OxygenLevel.get_all() do
      unless Components.OxygenCooldown.exists?(entity) do
        oxygen_capacity = Components.OxygenCapacity.get(entity)

        if oxygen < oxygen_capacity do
          new_oxygen = Enum.min([oxygen_capacity, oxygen + 1])
          Components.OxygenLevel.update(entity, new_oxygen)
        end
      end
    end
  end
end
