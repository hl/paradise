defmodule Paradise.AstronautsTest do
  use Paradise.DataCase

  alias Paradise.Astronauts

  import Paradise.AstronautsFixtures
  alias Paradise.Astronauts.{Astronaut, AstronautToken}

  describe "get_astronaut_by_email/1" do
    test "does not return the astronaut if the email does not exist" do
      refute Astronauts.get_astronaut_by_email("unknown@example.com")
    end

    test "returns the astronaut if the email exists" do
      %{id: id} = astronaut = astronaut_fixture()
      assert %Astronaut{id: ^id} = Astronauts.get_astronaut_by_email(astronaut.email)
    end
  end

  describe "get_astronaut_by_email_and_password/2" do
    test "does not return the astronaut if the email does not exist" do
      refute Astronauts.get_astronaut_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the astronaut if the password is not valid" do
      astronaut = astronaut_fixture()
      refute Astronauts.get_astronaut_by_email_and_password(astronaut.email, "invalid")
    end

    test "returns the astronaut if the email and password are valid" do
      %{id: id} = astronaut = astronaut_fixture()

      assert %Astronaut{id: ^id} =
               Astronauts.get_astronaut_by_email_and_password(astronaut.email, valid_astronaut_password())
    end
  end

  describe "get_astronaut!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Astronauts.get_astronaut!("11111111-1111-1111-1111-111111111111")
      end
    end

    test "returns the astronaut with the given id" do
      %{id: id} = astronaut = astronaut_fixture()
      assert %Astronaut{id: ^id} = Astronauts.get_astronaut!(astronaut.id)
    end
  end

  describe "register_astronaut/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Astronauts.register_astronaut(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Astronauts.register_astronaut(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Astronauts.register_astronaut(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = astronaut_fixture()
      {:error, changeset} = Astronauts.register_astronaut(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Astronauts.register_astronaut(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers astronauts with a hashed password" do
      email = unique_astronaut_email()
      {:ok, astronaut} = Astronauts.register_astronaut(valid_astronaut_attributes(email: email))
      assert astronaut.email == email
      assert is_binary(astronaut.hashed_password)
      assert is_nil(astronaut.confirmed_at)
      assert is_nil(astronaut.password)
    end
  end

  describe "change_astronaut_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Astronauts.change_astronaut_registration(%Astronaut{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_astronaut_email()
      password = valid_astronaut_password()

      changeset =
        Astronauts.change_astronaut_registration(
          %Astronaut{},
          valid_astronaut_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_astronaut_email/2" do
    test "returns a astronaut changeset" do
      assert %Ecto.Changeset{} = changeset = Astronauts.change_astronaut_email(%Astronaut{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_astronaut_email/3" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "requires email to change", %{astronaut: astronaut} do
      {:error, changeset} = Astronauts.apply_astronaut_email(astronaut, valid_astronaut_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{astronaut: astronaut} do
      {:error, changeset} =
        Astronauts.apply_astronaut_email(astronaut, valid_astronaut_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{astronaut: astronaut} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Astronauts.apply_astronaut_email(astronaut, valid_astronaut_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{astronaut: astronaut} do
      %{email: email} = astronaut_fixture()
      password = valid_astronaut_password()

      {:error, changeset} = Astronauts.apply_astronaut_email(astronaut, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{astronaut: astronaut} do
      {:error, changeset} =
        Astronauts.apply_astronaut_email(astronaut, "invalid", %{email: unique_astronaut_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{astronaut: astronaut} do
      email = unique_astronaut_email()
      {:ok, astronaut} = Astronauts.apply_astronaut_email(astronaut, valid_astronaut_password(), %{email: email})
      assert astronaut.email == email
      assert Astronauts.get_astronaut!(astronaut.id).email != email
    end
  end

  describe "deliver_astronaut_update_email_instructions/3" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "sends token through notification", %{astronaut: astronaut} do
      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_update_email_instructions(astronaut, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert astronaut_token = Repo.get_by(AstronautToken, token: :crypto.hash(:sha256, token))
      assert astronaut_token.astronaut_id == astronaut.id
      assert astronaut_token.sent_to == astronaut.email
      assert astronaut_token.context == "change:current@example.com"
    end
  end

  describe "update_astronaut_email/2" do
    setup do
      astronaut = astronaut_fixture()
      email = unique_astronaut_email()

      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_update_email_instructions(%{astronaut | email: email}, astronaut.email, url)
        end)

      %{astronaut: astronaut, token: token, email: email}
    end

    test "updates the email with a valid token", %{astronaut: astronaut, token: token, email: email} do
      assert Astronauts.update_astronaut_email(astronaut, token) == :ok
      changed_astronaut = Repo.get!(Astronaut, astronaut.id)
      assert changed_astronaut.email != astronaut.email
      assert changed_astronaut.email == email
      assert changed_astronaut.confirmed_at
      assert changed_astronaut.confirmed_at != astronaut.confirmed_at
      refute Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not update email with invalid token", %{astronaut: astronaut} do
      assert Astronauts.update_astronaut_email(astronaut, "oops") == :error
      assert Repo.get!(Astronaut, astronaut.id).email == astronaut.email
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not update email if astronaut email changed", %{astronaut: astronaut, token: token} do
      assert Astronauts.update_astronaut_email(%{astronaut | email: "current@example.com"}, token) == :error
      assert Repo.get!(Astronaut, astronaut.id).email == astronaut.email
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not update email if token expired", %{astronaut: astronaut, token: token} do
      {1, nil} = Repo.update_all(AstronautToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Astronauts.update_astronaut_email(astronaut, token) == :error
      assert Repo.get!(Astronaut, astronaut.id).email == astronaut.email
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end
  end

  describe "change_astronaut_password/2" do
    test "returns a astronaut changeset" do
      assert %Ecto.Changeset{} = changeset = Astronauts.change_astronaut_password(%Astronaut{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Astronauts.change_astronaut_password(%Astronaut{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_astronaut_password/3" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "validates password", %{astronaut: astronaut} do
      {:error, changeset} =
        Astronauts.update_astronaut_password(astronaut, valid_astronaut_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{astronaut: astronaut} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Astronauts.update_astronaut_password(astronaut, valid_astronaut_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{astronaut: astronaut} do
      {:error, changeset} =
        Astronauts.update_astronaut_password(astronaut, "invalid", %{password: valid_astronaut_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{astronaut: astronaut} do
      {:ok, astronaut} =
        Astronauts.update_astronaut_password(astronaut, valid_astronaut_password(), %{
          password: "new valid password"
        })

      assert is_nil(astronaut.password)
      assert Astronauts.get_astronaut_by_email_and_password(astronaut.email, "new valid password")
    end

    test "deletes all tokens for the given astronaut", %{astronaut: astronaut} do
      _ = Astronauts.generate_astronaut_session_token(astronaut)

      {:ok, _} =
        Astronauts.update_astronaut_password(astronaut, valid_astronaut_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end
  end

  describe "generate_astronaut_session_token/1" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "generates a token", %{astronaut: astronaut} do
      token = Astronauts.generate_astronaut_session_token(astronaut)
      assert astronaut_token = Repo.get_by(AstronautToken, token: token)
      assert astronaut_token.context == "session"

      # Creating the same token for another astronaut should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AstronautToken{
          token: astronaut_token.token,
          astronaut_id: astronaut_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_astronaut_by_session_token/1" do
    setup do
      astronaut = astronaut_fixture()
      token = Astronauts.generate_astronaut_session_token(astronaut)
      %{astronaut: astronaut, token: token}
    end

    test "returns astronaut by token", %{astronaut: astronaut, token: token} do
      assert session_astronaut = Astronauts.get_astronaut_by_session_token(token)
      assert session_astronaut.id == astronaut.id
    end

    test "does not return astronaut for invalid token" do
      refute Astronauts.get_astronaut_by_session_token("oops")
    end

    test "does not return astronaut for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AstronautToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Astronauts.get_astronaut_by_session_token(token)
    end
  end

  describe "delete_astronaut_session_token/1" do
    test "deletes the token" do
      astronaut = astronaut_fixture()
      token = Astronauts.generate_astronaut_session_token(astronaut)
      assert Astronauts.delete_astronaut_session_token(token) == :ok
      refute Astronauts.get_astronaut_by_session_token(token)
    end
  end

  describe "deliver_astronaut_confirmation_instructions/2" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "sends token through notification", %{astronaut: astronaut} do
      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_confirmation_instructions(astronaut, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert astronaut_token = Repo.get_by(AstronautToken, token: :crypto.hash(:sha256, token))
      assert astronaut_token.astronaut_id == astronaut.id
      assert astronaut_token.sent_to == astronaut.email
      assert astronaut_token.context == "confirm"
    end
  end

  describe "confirm_astronaut/1" do
    setup do
      astronaut = astronaut_fixture()

      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_confirmation_instructions(astronaut, url)
        end)

      %{astronaut: astronaut, token: token}
    end

    test "confirms the email with a valid token", %{astronaut: astronaut, token: token} do
      assert {:ok, confirmed_astronaut} = Astronauts.confirm_astronaut(token)
      assert confirmed_astronaut.confirmed_at
      assert confirmed_astronaut.confirmed_at != astronaut.confirmed_at
      assert Repo.get!(Astronaut, astronaut.id).confirmed_at
      refute Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not confirm with invalid token", %{astronaut: astronaut} do
      assert Astronauts.confirm_astronaut("oops") == :error
      refute Repo.get!(Astronaut, astronaut.id).confirmed_at
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not confirm email if token expired", %{astronaut: astronaut, token: token} do
      {1, nil} = Repo.update_all(AstronautToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Astronauts.confirm_astronaut(token) == :error
      refute Repo.get!(Astronaut, astronaut.id).confirmed_at
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end
  end

  describe "deliver_astronaut_reset_password_instructions/2" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "sends token through notification", %{astronaut: astronaut} do
      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_reset_password_instructions(astronaut, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert astronaut_token = Repo.get_by(AstronautToken, token: :crypto.hash(:sha256, token))
      assert astronaut_token.astronaut_id == astronaut.id
      assert astronaut_token.sent_to == astronaut.email
      assert astronaut_token.context == "reset_password"
    end
  end

  describe "get_astronaut_by_reset_password_token/1" do
    setup do
      astronaut = astronaut_fixture()

      token =
        extract_astronaut_token(fn url ->
          Astronauts.deliver_astronaut_reset_password_instructions(astronaut, url)
        end)

      %{astronaut: astronaut, token: token}
    end

    test "returns the astronaut with valid token", %{astronaut: %{id: id}, token: token} do
      assert %Astronaut{id: ^id} = Astronauts.get_astronaut_by_reset_password_token(token)
      assert Repo.get_by(AstronautToken, astronaut_id: id)
    end

    test "does not return the astronaut with invalid token", %{astronaut: astronaut} do
      refute Astronauts.get_astronaut_by_reset_password_token("oops")
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end

    test "does not return the astronaut if token expired", %{astronaut: astronaut, token: token} do
      {1, nil} = Repo.update_all(AstronautToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Astronauts.get_astronaut_by_reset_password_token(token)
      assert Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end
  end

  describe "reset_astronaut_password/2" do
    setup do
      %{astronaut: astronaut_fixture()}
    end

    test "validates password", %{astronaut: astronaut} do
      {:error, changeset} =
        Astronauts.reset_astronaut_password(astronaut, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{astronaut: astronaut} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Astronauts.reset_astronaut_password(astronaut, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{astronaut: astronaut} do
      {:ok, updated_astronaut} = Astronauts.reset_astronaut_password(astronaut, %{password: "new valid password"})
      assert is_nil(updated_astronaut.password)
      assert Astronauts.get_astronaut_by_email_and_password(astronaut.email, "new valid password")
    end

    test "deletes all tokens for the given astronaut", %{astronaut: astronaut} do
      _ = Astronauts.generate_astronaut_session_token(astronaut)
      {:ok, _} = Astronauts.reset_astronaut_password(astronaut, %{password: "new valid password"})
      refute Repo.get_by(AstronautToken, astronaut_id: astronaut.id)
    end
  end

  describe "inspect/2 for the Astronaut module" do
    test "does not include password" do
      refute inspect(%Astronaut{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
