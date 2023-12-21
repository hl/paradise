defmodule ParadiseWeb.AstronautConfirmationLiveTest do
  use ParadiseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Paradise.AstronautsFixtures

  alias Paradise.Astronauts
  alias Paradise.Repo

  setup do
    %{astronaut: astronaut_fixture()}
  end

  describe "Confirm astronaut" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/astronauts/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, astronaut: astronaut} do
      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_confirmation_instructions(astronaut, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Astronaut confirmed successfully"

      assert Astronauts.get_astronaut!(astronaut.id).confirmed_at
      refute get_session(conn, :astronaut_token)
      assert Repo.all(Astronauts.AstronautToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Astronaut confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_astronaut(astronaut)

      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, astronaut: astronaut} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Astronaut confirmation link is invalid or it has expired"

      refute Astronauts.get_astronaut!(astronaut.id).confirmed_at
    end
  end
end
