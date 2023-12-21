defmodule ParadiseWeb.AstronautSessionControllerTest do
  use ParadiseWeb.ConnCase

  import Paradise.AstronautsFixtures

  setup do
    %{astronaut: astronaut_fixture()}
  end

  describe "POST /astronauts/log_in" do
    test "logs the astronaut in", %{conn: conn, astronaut: astronaut} do
      conn =
        post(conn, ~p"/astronauts/log_in", %{
          "astronaut" => %{"email" => astronaut.email, "password" => valid_astronaut_password()}
        })

      assert get_session(conn, :astronaut_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ astronaut.email
      assert response =~ ~p"/astronauts/settings"
      assert response =~ ~p"/astronauts/log_out"
    end

    test "logs the astronaut in with remember me", %{conn: conn, astronaut: astronaut} do
      conn =
        post(conn, ~p"/astronauts/log_in", %{
          "astronaut" => %{
            "email" => astronaut.email,
            "password" => valid_astronaut_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_paradise_web_astronaut_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the astronaut in with return to", %{conn: conn, astronaut: astronaut} do
      conn =
        conn
        |> init_test_session(astronaut_return_to: "/foo/bar")
        |> post(~p"/astronauts/log_in", %{
          "astronaut" => %{
            "email" => astronaut.email,
            "password" => valid_astronaut_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, astronaut: astronaut} do
      conn =
        conn
        |> post(~p"/astronauts/log_in", %{
          "_action" => "registered",
          "astronaut" => %{
            "email" => astronaut.email,
            "password" => valid_astronaut_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, astronaut: astronaut} do
      conn =
        conn
        |> post(~p"/astronauts/log_in", %{
          "_action" => "password_updated",
          "astronaut" => %{
            "email" => astronaut.email,
            "password" => valid_astronaut_password()
          }
        })

      assert redirected_to(conn) == ~p"/astronauts/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/astronauts/log_in", %{
          "astronaut" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/astronauts/log_in"
    end
  end

  describe "DELETE /astronauts/log_out" do
    test "logs the astronaut out", %{conn: conn, astronaut: astronaut} do
      conn = conn |> log_in_astronaut(astronaut) |> delete(~p"/astronauts/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :astronaut_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the astronaut is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/astronauts/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :astronaut_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
