defmodule Paradise.Systems.ConsumeOxygen do
  @moduledoc """
  Documentation for ConsumeOxygen system.
  """
  @behaviour ECSx.System

  alias Paradise.Components

  @impl ECSx.System
  def run do
    for {entity, oxygen} <- Components.OxygenLevel.get_all() do
    end
  end
end
