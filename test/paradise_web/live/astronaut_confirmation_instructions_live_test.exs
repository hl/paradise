defmodule ParadiseWeb.AstronautConfirmationInstructionsLiveTest do
  use ParadiseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Paradise.AstronautsFixtures

  alias Paradise.Astronauts
  alias Paradise.Repo

  setup do
    %{astronaut: astronaut_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/astronauts/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, astronaut: astronaut} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", astronaut: %{email: astronaut.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Astronauts.AstronautToken, astronaut_id: astronaut.id).context == "confirm"
    end

    test "does not send confirmation token if astronaut is confirmed", %{conn: conn, astronaut: astronaut} do
      Repo.update!(Astronauts.Astronaut.confirm_changeset(astronaut))

      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", astronaut: %{email: astronaut.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Astronauts.AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", astronaut: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Astronauts.AstronautToken) == []
    end
  end
end
