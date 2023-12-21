defmodule ParadiseWeb.AstronautSessionController do
  use ParadiseWeb, :controller

  alias Paradise.Astronauts
  alias ParadiseWeb.AstronautAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:astronaut_return_to, ~p"/astronauts/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"astronaut" => astronaut_params}, info) do
    %{"email" => email, "password" => password} = astronaut_params

    if astronaut = Astronauts.get_astronaut_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> AstronautAuth.log_in_astronaut(astronaut, astronaut_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/astronauts/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AstronautAuth.log_out_astronaut()
  end
end
