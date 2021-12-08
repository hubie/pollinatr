defmodule Pollinatr.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email_address, :string, null: false
      add :role, :string, null: false
      add :nickname, :string

      timestamps()
    end

    create unique_index(:users, [:email_address])
    # create unique_index(:users, [:nickname])
  end
end
