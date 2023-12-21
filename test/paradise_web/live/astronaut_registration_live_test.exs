defmodule ParadiseWeb.AstronautRegistrationLiveTest do
  use ParadiseWeb.ConnCase

  import Phoenix.LiveViewTest
  import Paradise.AstronautsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/astronauts/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_astronaut(astronaut_fixture())
        |> live(~p"/astronauts/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(astronaut: %{"email" => "with spaces", "password" => "too short"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 12 character"
    end
  end

  describe "register astronaut" do
    test "creates account and logs the astronaut in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/register")

      email = unique_astronaut_email()
      form = form(lv, "#registration_form", astronaut: valid_astronaut_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/register")

      astronaut = astronaut_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          astronaut: %{"email" => astronaut.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/astronauts/register")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/astronauts/log_in")

      assert login_html =~ "Log in"
    end
  end
end
