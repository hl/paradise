defmodule Paradise.Systems.MoveEntity do
  @moduledoc """
  Documentation for MoveEntity system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, x_velocity} <- Components.XVelocity.get_all() do
      x_position = Components.XPosition.get(entity)
      new_x_position = calculate_new_position(x_position, x_velocity)
      Components.XPosition.update(entity, new_x_position)
    end

    for {entity, y_velocity} <- Components.YVelocity.get_all() do
      y_position = Components.YPosition.get(entity)
      new_y_position = calculate_new_position(y_position, y_velocity)
      Components.YPosition.update(entity, new_y_position)
    end
  end

  defp calculate_new_position(current_position, velocity) do
    new_position = current_position + velocity
    new_position = Enum.min([new_position, 99])

    Enum.max([new_position, 0])
  end
end
