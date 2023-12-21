defmodule ParadiseWeb.GameLive do
  use ParadiseWeb, :live_view

  alias Paradise.Astronauts
  alias Paradise.Components

  @impl true
  def mount(_params, %{"astronaut_token" => token} = _session, socket) do
    astronaut = Astronauts.get_astronaut_by_session_token(token)

    socket =
      socket
      |> assign(astronaut_entity: astronaut.id)
      |> assign(keys: MapSet.new())
      |> assign(game_world_size: 100, screen_height: 30, screen_width: 50)
      |> assign_loading_state()

    if connected?(socket) do
      unless Components.AstronautSpawned.exists?(astronaut.id) do
        ECSx.ClientEvents.add(astronaut.id, :spawn_astronaut)
      end

      send(self(), :first_load)
    end

    {:ok, socket}
  end

  defp assign_loading_state(socket) do
    assign(socket,
      name: nil,
      x_coord: nil,
      y_coord: nil,
      energy: nil,
      x_offset: 0,
      y_offset: 0,
      astronaut_image_file: nil,
      loading: true
    )
  end

  @impl true
  def handle_info(:first_load, socket) do
    :ok = wait_for_spawn(socket.assigns.astronaut_entity)

    socket =
      socket
      |> assign_astronaut()
      |> assign_offsets()
      |> assign(loading: false)

    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_astronaut()
      |> assign_offsets()

    {:noreply, socket}
  end

  defp wait_for_spawn(astronaut_entity) do
    if Components.AstronautSpawned.exists?(astronaut_entity) do
      :ok
    else
      Process.sleep(10)
      wait_for_spawn(astronaut_entity)
    end
  end

  defp assign_astronaut(socket) do
    name = Components.Description.get(socket.assigns.astronaut_entity)
    x = Components.XPosition.get(socket.assigns.astronaut_entity)
    y = Components.YPosition.get(socket.assigns.astronaut_entity)
    energy = Components.Energy.get(socket.assigns.astronaut_entity)
    image = Components.ImageFile.get(socket.assigns.astronaut_entity)

    assign(socket,
      name: name,
      x_coord: x,
      y_coord: y,
      energy: energy,
      astronaut_image_file: image
    )
  end

  defp assign_offsets(socket) do
    %{screen_width: screen_width, screen_height: screen_height} = socket.assigns
    %{x_coord: x, y_coord: y, game_world_size: game_world_size} = socket.assigns

    x_offset = calculate_offset(x, screen_width, game_world_size)
    y_offset = calculate_offset(y, screen_height, game_world_size)

    assign(socket, x_offset: x_offset, y_offset: y_offset)
  end

  defp calculate_offset(coord, screen_size, game_world_size) do
    case coord - div(screen_size, 2) do
      offset when offset < 0 -> 0
      offset when offset > game_world_size - screen_size -> game_world_size - screen_size
      offset -> offset
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      {:noreply, socket}
    else
      maybe_add_client_event(socket.assigns.astronaut_entity, key, &keydown/1)
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    maybe_add_client_event(socket.assigns.astronaut_entity, key, &keyup/1)
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp maybe_add_client_event(astronaut_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(astronaut_entity, event)
    end
  end

  defp keydown(key) when key in ~w(w W ArrowUp), do: {:move, :up}
  defp keydown(key) when key in ~w(a A ArrowLeft), do: {:move, :left}
  defp keydown(key) when key in ~w(s S ArrowDown), do: {:move, :down}
  defp keydown(key) when key in ~w(d D ArrowRight), do: {:move, :right}
  defp keydown(_key), do: :noop

  defp keyup(key) when key in ~w(w W ArrowUp), do: {:stop_move, :up}
  defp keyup(key) when key in ~w(a A ArrowLeft), do: {:stop_move, :left}
  defp keyup(key) when key in ~w(s S ArrowDown), do: {:stop_move, :down}
  defp keyup(key) when key in ~w(d D ArrowRight), do: {:stop_move, :right}
  defp keyup(_key), do: :noop

  @impl true
  def render(assigns) do
    ~H"""
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup">
      <svg
        viewBox={"#{@x_offset} #{@y_offset} #{@screen_width} #{@screen_height}"}
        preserveAspectRatio="xMinYMin slice"
      >
        <rect
          width={@game_world_size}
          height={@game_world_size}
          style="fill:red;stroke:black;stroke-width:5;opacity:0.5"
        />

        <%= if @loading do %>
          <text x={div(@screen_width, 2)} y={div(@screen_height, 2)} style="font: 1px serif">
            Loading...
          </text>
        <% else %>
          <image
            x={@x_coord}
            y={@y_coord}
            width="1"
            height="1"
            href={~p"/images/#{@astronaut_image_file}"}
          />
          <text x={@x_offset} y={@y_offset + 1} style="font: 1px serif">
            Name: <%= @name %> Energy: <%= @energy %> Coordinates: {<%= @x_coord %>, <%= @y_coord %>} Offset: {<%= @x_offset %>, <%= @y_offset %>}
          </text>
        <% end %>
      </svg>
    </div>
    """
  end
end
