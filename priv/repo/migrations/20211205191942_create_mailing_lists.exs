defmodule Pollinatr.Repo.Migrations.CreateEmailingLists do
  use Ecto.Migration

  def change do
    create table(:emailing_lists) do
      add :name, :string
      add :description, :string
      add :subscription_type, :string
      add :tenant, :string

      timestamps()
    end
  end
end
