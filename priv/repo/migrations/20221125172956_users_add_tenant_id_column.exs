defmodule Pollinatr.Repo.Migrations.UsersAddTenantIdColumn do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :tenant_id, references("tenants", column: :id, type: :uuid), null: false
    end

    create unique_index(:users, [:tenant_id, :email_address])
    drop index(:users, [:email_address])
  end
end
