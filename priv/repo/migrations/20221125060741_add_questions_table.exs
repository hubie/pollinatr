defmodule Pollinatr.Repo.Migrations.AddQuestionsTable do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references("tenants", column: :id, type: :uuid), null: false
      add :sort_order, :integer, null: false
      add :question, :string, null: false
      add :answer_type, :string, null: false

      timestamps()
    end

    create index(:questions, [:tenant_id, :sort_order])
  end
end
