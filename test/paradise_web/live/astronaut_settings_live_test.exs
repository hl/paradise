defmodule ParadiseWeb.AstronautSettingsLiveTest do
  use ParadiseWeb.ConnCase

  alias Paradise.Astronauts
  import Phoenix.LiveViewTest
  import Paradise.AstronautsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_astronaut(astronaut_fixture())
        |> live(~p"/astronauts/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if astronaut is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/astronauts/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/astronauts/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_astronaut_password()
      astronaut = astronaut_fixture(%{password: password})
      %{conn: log_in_astronaut(conn, astronaut), astronaut: astronaut, password: password}
    end

    test "updates the astronaut email", %{conn: conn, password: password, astronaut: astronaut} do
      new_email = unique_astronaut_email()

      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "astronaut" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Astronauts.get_astronaut_by_email(astronaut.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "astronaut" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, astronaut: astronaut} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "astronaut" => %{"email" => astronaut.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_astronaut_password()
      astronaut = astronaut_fixture(%{password: password})
      %{conn: log_in_astronaut(conn, astronaut), astronaut: astronaut, password: password}
    end

    test "updates the astronaut password", %{conn: conn, astronaut: astronaut, password: password} do
      new_password = valid_astronaut_password()

      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "astronaut" => %{
            "email" => astronaut.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/astronauts/settings"

      assert get_session(new_password_conn, :astronaut_token) != get_session(conn, :astronaut_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Astronauts.get_astronaut_by_email_and_password(astronaut.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "astronaut" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "astronaut" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      astronaut = astronaut_fixture()
      email = unique_astronaut_email()

      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_update_email_instructions(%{astronaut | email: email}, astronaut.email, url)
        end)

      %{conn: log_in_astronaut(conn, astronaut), token: token, email: email, astronaut: astronaut}
    end

    test "updates the astronaut email once", %{conn: conn, astronaut: astronaut, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/astronauts/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/astronauts/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Astronauts.get_astronaut_by_email(astronaut.email)
      assert Astronauts.get_astronaut_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/astronauts/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/astronauts/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, astronaut: astronaut} do
      {:error, redirect} = live(conn, ~p"/astronauts/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/astronauts/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Astronauts.get_astronaut_by_email(astronaut.email)
    end

    test "redirects if astronaut is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/astronauts/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/astronauts/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
