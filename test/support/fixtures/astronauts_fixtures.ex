defmodule Paradise.AstronautsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Paradise.Astronauts` context.
  """

  def unique_astronaut_email, do: "astronaut#{System.unique_integer()}@example.com"
  def valid_astronaut_password, do: "hello world!"

  def valid_astronaut_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_astronaut_email(),
      password: valid_astronaut_password()
    })
  end

  def astronaut_fixture(attrs \\ %{}) do
    {:ok, astronaut} =
      attrs
      |> valid_astronaut_attributes()
      |> Paradise.Astronauts.register_astronaut()

    astronaut
  end

  def extract_astronaut_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
