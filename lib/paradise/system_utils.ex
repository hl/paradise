defmodule Paradise.SystemUtils do
  @moduledoc """
  Useful math functions used by multiple systems.
  """

  alias Paradise.Components

  def distance_between(entity_1, entity_2) do
    x_1 = Components.XPosition.get(entity_1)
    x_2 = Components.XPosition.get(entity_2)
    y_1 = Components.YPosition.get(entity_1)
    y_2 = Components.YPosition.get(entity_2)

    x = abs(x_1 - x_2)
    y = abs(y_1 - y_2)

    :math.sqrt(x ** 2 + y ** 2)
  end
end
