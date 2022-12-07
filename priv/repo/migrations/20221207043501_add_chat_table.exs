defmodule Pollinatr.Repo.Migrations.AddChatTable do
  use Ecto.Migration

  def change do
    create table(:chat_log, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false, default: fragment("gen_random_uuid()")
      add :tenant_id, references("tenants", column: :id, type: :uuid), null: false
      add :user_id, references("users", column: :id, type: :integer), null: false

      add :message, :text, null: false
      timestamps()
    end

    create index(:chat_log, [:tenant_id, :inserted_at])
  end
end
