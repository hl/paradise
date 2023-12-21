defmodule Paradise.Astronauts.AstronautNotifier do
  import Swoosh.Email

  alias Paradise.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Paradise", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(astronaut, url) do
    deliver(astronaut.email, "Confirmation instructions", """

    ==============================

    Hi #{astronaut.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a astronaut password.
  """
  def deliver_reset_password_instructions(astronaut, url) do
    deliver(astronaut.email, "Reset password instructions", """

    ==============================

    Hi #{astronaut.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a astronaut email.
  """
  def deliver_update_email_instructions(astronaut, url) do
    deliver(astronaut.email, "Update email instructions", """

    ==============================

    Hi #{astronaut.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
