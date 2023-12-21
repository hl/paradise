defmodule ParadiseWeb.AstronautAuthTest do
  use ParadiseWeb.ConnCase

  alias Phoenix.LiveView
  alias Paradise.Astronauts
  alias ParadiseWeb.AstronautAuth
  import Paradise.AstronautsFixtures

  @remember_me_cookie "_paradise_web_astronaut_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, ParadiseWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{astronaut: astronaut_fixture(), conn: conn}
  end

  describe "log_in_astronaut/3" do
    test "stores the astronaut token in the session", %{conn: conn, astronaut: astronaut} do
      conn = AstronautAuth.log_in_astronaut(conn, astronaut)
      assert token = get_session(conn, :astronaut_token)
      assert get_session(conn, :live_socket_id) == "astronauts_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Astronauts.get_astronaut_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, astronaut: astronaut} do
      conn = conn |> put_session(:to_be_removed, "value") |> AstronautAuth.log_in_astronaut(astronaut)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, astronaut: astronaut} do
      conn = conn |> put_session(:astronaut_return_to, "/hello") |> AstronautAuth.log_in_astronaut(astronaut)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, astronaut: astronaut} do
      conn = conn |> fetch_cookies() |> AstronautAuth.log_in_astronaut(astronaut, %{"remember_me" => "true"})
      assert get_session(conn, :astronaut_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :astronaut_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_astronaut/1" do
    test "erases session and cookies", %{conn: conn, astronaut: astronaut} do
      astronaut_token = Astronauts.generate_astronaut_session_token(astronaut)

      conn =
        conn
        |> put_session(:astronaut_token, astronaut_token)
        |> put_req_cookie(@remember_me_cookie, astronaut_token)
        |> fetch_cookies()
        |> AstronautAuth.log_out_astronaut()

      refute get_session(conn, :astronaut_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Astronauts.get_astronaut_by_session_token(astronaut_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "astronauts_sessions:abcdef-token"
      ParadiseWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> AstronautAuth.log_out_astronaut()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if astronaut is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> AstronautAuth.log_out_astronaut()
      refute get_session(conn, :astronaut_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_astronaut/2" do
    test "authenticates astronaut from session", %{conn: conn, astronaut: astronaut} do
      astronaut_token = Astronauts.generate_astronaut_session_token(astronaut)
      conn = conn |> put_session(:astronaut_token, astronaut_token) |> AstronautAuth.fetch_current_astronaut([])
      assert conn.assigns.current_astronaut.id == astronaut.id
    end

    test "authenticates astronaut from cookies", %{conn: conn, astronaut: astronaut} do
      logged_in_conn =
        conn |> fetch_cookies() |> AstronautAuth.log_in_astronaut(astronaut, %{"remember_me" => "true"})

      astronaut_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> AstronautAuth.fetch_current_astronaut([])

      assert conn.assigns.current_astronaut.id == astronaut.id
      assert get_session(conn, :astronaut_token) == astronaut_token

      assert get_session(conn, :live_socket_id) ==
               "astronauts_sessions:#{Base.url_encode64(astronaut_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, astronaut: astronaut} do
      _ = Astronauts.generate_astronaut_session_token(astronaut)
      conn = AstronautAuth.fetch_current_astronaut(conn, [])
      refute get_session(conn, :astronaut_token)
      refute conn.assigns.current_astronaut
    end
  end

  describe "on_mount: mount_current_astronaut" do
    test "assigns current_astronaut based on a valid astronaut_token", %{conn: conn, astronaut: astronaut} do
      astronaut_token = Astronauts.generate_astronaut_session_token(astronaut)
      session = conn |> put_session(:astronaut_token, astronaut_token) |> get_session()

      {:cont, updated_socket} =
        AstronautAuth.on_mount(:mount_current_astronaut, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_astronaut.id == astronaut.id
    end

    test "assigns nil to current_astronaut assign if there isn't a valid astronaut_token", %{conn: conn} do
      astronaut_token = "invalid_token"
      session = conn |> put_session(:astronaut_token, astronaut_token) |> get_session()

      {:cont, updated_socket} =
        AstronautAuth.on_mount(:mount_current_astronaut, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_astronaut == nil
    end

    test "assigns nil to current_astronaut assign if there isn't a astronaut_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        AstronautAuth.on_mount(:mount_current_astronaut, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_astronaut == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_astronaut based on a valid astronaut_token", %{conn: conn, astronaut: astronaut} do
      astronaut_token = Astronauts.generate_astronaut_session_token(astronaut)
      session = conn |> put_session(:astronaut_token, astronaut_token) |> get_session()

      {:cont, updated_socket} =
        AstronautAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_astronaut.id == astronaut.id
    end

    test "redirects to login page if there isn't a valid astronaut_token", %{conn: conn} do
      astronaut_token = "invalid_token"
      session = conn |> put_session(:astronaut_token, astronaut_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: ParadiseWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = AstronautAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_astronaut == nil
    end

    test "redirects to login page if there isn't a astronaut_token", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: ParadiseWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = AstronautAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_astronaut == nil
    end
  end

  describe "on_mount: :redirect_if_astronaut_is_authenticated" do
    test "redirects if there is an authenticated  astronaut ", %{conn: conn, astronaut: astronaut} do
      astronaut_token = Astronauts.generate_astronaut_session_token(astronaut)
      session = conn |> put_session(:astronaut_token, astronaut_token) |> get_session()

      assert {:halt, _updated_socket} =
               AstronautAuth.on_mount(
                 :redirect_if_astronaut_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "doesn't redirect if there is no authenticated astronaut", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               AstronautAuth.on_mount(
                 :redirect_if_astronaut_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_astronaut_is_authenticated/2" do
    test "redirects if astronaut is authenticated", %{conn: conn, astronaut: astronaut} do
      conn = conn |> assign(:current_astronaut, astronaut) |> AstronautAuth.redirect_if_astronaut_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if astronaut is not authenticated", %{conn: conn} do
      conn = AstronautAuth.redirect_if_astronaut_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_astronaut/2" do
    test "redirects if astronaut is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> AstronautAuth.require_authenticated_astronaut([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/astronauts/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> AstronautAuth.require_authenticated_astronaut([])

      assert halted_conn.halted
      assert get_session(halted_conn, :astronaut_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> AstronautAuth.require_authenticated_astronaut([])

      assert halted_conn.halted
      assert get_session(halted_conn, :astronaut_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> AstronautAuth.require_authenticated_astronaut([])

      assert halted_conn.halted
      refute get_session(halted_conn, :astronaut_return_to)
    end

    test "does not redirect if astronaut is authenticated", %{conn: conn, astronaut: astronaut} do
      conn = conn |> assign(:current_astronaut, astronaut) |> AstronautAuth.require_authenticated_astronaut([])
      refute conn.halted
      refute conn.status
    end
  end
end
