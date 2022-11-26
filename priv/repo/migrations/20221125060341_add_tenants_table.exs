defmodule Pollinatr.Repo.Migrations.AddTenantsTable do
  use Ecto.Migration

  def change do
    create table(:tenants, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :name, :string, null: false

      timestamps()
    end
  end
end
