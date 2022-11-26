defmodule Pollinatr.Repo.Migrations.AddAnswersTable do
  use Ecto.Migration

  def change do
    create table(:multiple_choice_answers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :tenant_id, references("tenants", column: :id, type: :uuid), null: false
      add :question_id, references("questions", column: :id, type: :uuid), null: false
      add :sort_order, :integer, null: false
      add :answer, :string, null: false

      timestamps()
    end

    create index(:multiple_choice_answers, [:tenant_id, :question_id, :sort_order])
  end
end
