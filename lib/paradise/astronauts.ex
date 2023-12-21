defmodule Paradise.Astronauts do
  @moduledoc """
  The Astronauts context.
  """

  import Ecto.Query, warn: false
  alias Paradise.Repo

  alias Paradise.Astronauts.{Astronaut, AstronautToken, AstronautNotifier}

  ## Database getters

  @doc """
  Gets a astronaut by email.

  ## Examples

      iex> get_astronaut_by_email("foo@example.com")
      %Astronaut{}

      iex> get_astronaut_by_email("unknown@example.com")
      nil

  """
  def get_astronaut_by_email(email) when is_binary(email) do
    Repo.get_by(Astronaut, email: email)
  end

  @doc """
  Gets a astronaut by email and password.

  ## Examples

      iex> get_astronaut_by_email_and_password("foo@example.com", "correct_password")
      %Astronaut{}

      iex> get_astronaut_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_astronaut_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    astronaut = Repo.get_by(Astronaut, email: email)
    if Astronaut.valid_password?(astronaut, password), do: astronaut
  end

  @doc """
  Gets a single astronaut.

  Raises `Ecto.NoResultsError` if the Astronaut does not exist.

  ## Examples

      iex> get_astronaut!(123)
      %Astronaut{}

      iex> get_astronaut!(456)
      ** (Ecto.NoResultsError)

  """
  def get_astronaut!(id), do: Repo.get!(Astronaut, id)

  ## Astronaut registration

  @doc """
  Registers a astronaut.

  ## Examples

      iex> register_astronaut(%{field: value})
      {:ok, %Astronaut{}}

      iex> register_astronaut(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_astronaut(attrs) do
    %Astronaut{}
    |> Astronaut.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking astronaut changes.

  ## Examples

      iex> change_astronaut_registration(astronaut)
      %Ecto.Changeset{data: %Astronaut{}}

  """
  def change_astronaut_registration(%Astronaut{} = astronaut, attrs \\ %{}) do
    Astronaut.registration_changeset(astronaut, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the astronaut email.

  ## Examples

      iex> change_astronaut_email(astronaut)
      %Ecto.Changeset{data: %Astronaut{}}

  """
  def change_astronaut_email(astronaut, attrs \\ %{}) do
    Astronaut.email_changeset(astronaut, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_astronaut_email(astronaut, "valid password", %{email: ...})
      {:ok, %Astronaut{}}

      iex> apply_astronaut_email(astronaut, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_astronaut_email(astronaut, password, attrs) do
    astronaut
    |> Astronaut.email_changeset(attrs)
    |> Astronaut.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the astronaut email using the given token.

  If the token matches, the astronaut email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_astronaut_email(astronaut, token) do
    context = "change:#{astronaut.email}"

    with {:ok, query} <- AstronautToken.verify_change_email_token_query(token, context),
         %AstronautToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(astronaut_email_multi(astronaut, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp astronaut_email_multi(astronaut, email, context) do
    changeset =
      astronaut
      |> Astronaut.email_changeset(%{email: email})
      |> Astronaut.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:astronaut, changeset)
    |> Ecto.Multi.delete_all(:tokens, AstronautToken.by_astronaut_and_contexts_query(astronaut, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given astronaut.

  ## Examples

      iex> deliver_astronaut_update_email_instructions(astronaut, current_email, &url(~p"/astronauts/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_astronaut_update_email_instructions(%Astronaut{} = astronaut, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, astronaut_token} = AstronautToken.build_email_token(astronaut, "change:#{current_email}")

    Repo.insert!(astronaut_token)
    AstronautNotifier.deliver_update_email_instructions(astronaut, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the astronaut password.

  ## Examples

      iex> change_astronaut_password(astronaut)
      %Ecto.Changeset{data: %Astronaut{}}

  """
  def change_astronaut_password(astronaut, attrs \\ %{}) do
    Astronaut.password_changeset(astronaut, attrs, hash_password: false)
  end

  @doc """
  Updates the astronaut password.

  ## Examples

      iex> update_astronaut_password(astronaut, "valid password", %{password: ...})
      {:ok, %Astronaut{}}

      iex> update_astronaut_password(astronaut, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_astronaut_password(astronaut, password, attrs) do
    changeset =
      astronaut
      |> Astronaut.password_changeset(attrs)
      |> Astronaut.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:astronaut, changeset)
    |> Ecto.Multi.delete_all(:tokens, AstronautToken.by_astronaut_and_contexts_query(astronaut, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{astronaut: astronaut}} -> {:ok, astronaut}
      {:error, :astronaut, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_astronaut_session_token(astronaut) do
    {token, astronaut_token} = AstronautToken.build_session_token(astronaut)
    Repo.insert!(astronaut_token)
    token
  end

  @doc """
  Gets the astronaut with the given signed token.
  """
  def get_astronaut_by_session_token(token) do
    {:ok, query} = AstronautToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_astronaut_session_token(token) do
    Repo.delete_all(AstronautToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given astronaut.

  ## Examples

      iex> deliver_astronaut_confirmation_instructions(astronaut, &url(~p"/astronauts/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_astronaut_confirmation_instructions(confirmed_astronaut, &url(~p"/astronauts/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_astronaut_confirmation_instructions(%Astronaut{} = astronaut, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if astronaut.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, astronaut_token} = AstronautToken.build_email_token(astronaut, "confirm")
      Repo.insert!(astronaut_token)
      AstronautNotifier.deliver_confirmation_instructions(astronaut, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a astronaut by the given token.

  If the token matches, the astronaut account is marked as confirmed
  and the token is deleted.
  """
  def confirm_astronaut(token) do
    with {:ok, query} <- AstronautToken.verify_email_token_query(token, "confirm"),
         %Astronaut{} = astronaut <- Repo.one(query),
         {:ok, %{astronaut: astronaut}} <- Repo.transaction(confirm_astronaut_multi(astronaut)) do
      {:ok, astronaut}
    else
      _ -> :error
    end
  end

  defp confirm_astronaut_multi(astronaut) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:astronaut, Astronaut.confirm_changeset(astronaut))
    |> Ecto.Multi.delete_all(:tokens, AstronautToken.by_astronaut_and_contexts_query(astronaut, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given astronaut.

  ## Examples

      iex> deliver_astronaut_reset_password_instructions(astronaut, &url(~p"/astronauts/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_astronaut_reset_password_instructions(%Astronaut{} = astronaut, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, astronaut_token} = AstronautToken.build_email_token(astronaut, "reset_password")
    Repo.insert!(astronaut_token)
    AstronautNotifier.deliver_reset_password_instructions(astronaut, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the astronaut by reset password token.

  ## Examples

      iex> get_astronaut_by_reset_password_token("validtoken")
      %Astronaut{}

      iex> get_astronaut_by_reset_password_token("invalidtoken")
      nil

  """
  def get_astronaut_by_reset_password_token(token) do
    with {:ok, query} <- AstronautToken.verify_email_token_query(token, "reset_password"),
         %Astronaut{} = astronaut <- Repo.one(query) do
      astronaut
    else
      _ -> nil
    end
  end

  @doc """
  Resets the astronaut password.

  ## Examples

      iex> reset_astronaut_password(astronaut, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Astronaut{}}

      iex> reset_astronaut_password(astronaut, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_astronaut_password(astronaut, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:astronaut, Astronaut.password_changeset(astronaut, attrs))
    |> Ecto.Multi.delete_all(:tokens, AstronautToken.by_astronaut_and_contexts_query(astronaut, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{astronaut: astronaut}} -> {:ok, astronaut}
      {:error, :astronaut, changeset, _} -> {:error, changeset}
    end
  end
end
