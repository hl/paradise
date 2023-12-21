defmodule Paradise.Repo.Migrations.CreateAstronautsAuthTables do
  use Ecto.Migration

  def change do
    create table(:astronauts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false, collate: :nocase
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:astronauts, [:email])

    create table(:astronauts_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :astronaut_id, references(:astronauts, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :binary, null: false, size: 32
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:astronauts_tokens, [:astronaut_id])
    create unique_index(:astronauts_tokens, [:context, :token])
  end
end
