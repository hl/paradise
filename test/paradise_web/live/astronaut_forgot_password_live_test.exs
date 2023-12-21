defmodule ParadiseWeb.AstronautForgotPasswordLiveTest do
  use ParadiseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Paradise.AstronautsFixtures

  alias Paradise.Astronauts
  alias Paradise.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/astronauts/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/astronauts/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/astronauts/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_astronaut(astronaut_fixture())
        |> live(~p"/astronauts/reset_password")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, astronaut: astronaut} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", astronaut: %{"email" => astronaut.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Astronauts.AstronautToken, astronaut_id: astronaut.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", astronaut: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Astronauts.AstronautToken) == []
    end
  end
end
