defmodule Paradise.Systems.ClientEventHandler do
  @moduledoc """
  ClientEventHandler is responsible for processing client events.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()
    Enum.each(client_events, &process_one/1)
  end

  defp process_one({entity, :spawn_astronaut}) do
    Components.Description.add(entity, "Astronaut #" <> Enum.random(1..10_000), persist: true)
    Components.Level.add(entity, 1, persist: true)
    Components.EnergyCapacity.add(entity, 100, persist: true)
    Components.XPosition.add(entity, Enum.random(1..100), persist: true)
    Components.YPosition.add(entity, Enum.random(1..100), persist: true)
    Components.ImageFile.add(entity, "astronaut.svg", persist: true)

    Components.Energy.add(entity, 100)
    Components.XVelocity.add(entity, 0)
    Components.YVelocity.add(entity, 0)

    Components.AstronautSpawned.add(entity)
  end

  # Note Y movement will use screen positio (increasing Y goes down)
  defp process_one({entity, {:move, :up}}), do: Components.YVelocity.update(entity, -1)
  defp process_one({entity, {:move, :down}}), do: Components.YVelocity.update(entity, 1)
  defp process_one({entity, {:move, :right}}), do: Components.XVelocity.update(entity, 1)
  defp process_one({entity, {:move, :left}}), do: Components.XVelocity.update(entity, -1)
  defp process_one({entity, {:stop_move, :up}}), do: Components.YVelocity.update(entity, 0)
  defp process_one({entity, {:stop_move, :down}}), do: Components.YVelocity.update(entity, 0)
  defp process_one({entity, {:stop_move, :right}}), do: Components.XVelocity.update(entity, 0)
  defp process_one({entity, {:stop_move, :left}}), do: Components.XVelocity.update(entity, 0)

  defp process_one({entity, :rename, new_name}),
    do: Components.Description.update(entity, new_name)
end
