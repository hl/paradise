defmodule ParadiseWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ParadiseWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint ParadiseWeb.Endpoint

      use ParadiseWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ParadiseWeb.ConnCase
    end
  end

  setup tags do
    Paradise.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in astronauts.

      setup :register_and_log_in_astronaut

  It stores an updated connection and a registered astronaut in the
  test context.
  """
  def register_and_log_in_astronaut(%{conn: conn}) do
    astronaut = Paradise.AstronautsFixtures.astronaut_fixture()
    %{conn: log_in_astronaut(conn, astronaut), astronaut: astronaut}
  end

  @doc """
  Logs the given `astronaut` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_astronaut(conn, astronaut) do
    token = Paradise.Astronauts.generate_astronaut_session_token(astronaut)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:astronaut_token, token)
  end
end
