defmodule Pollinatr.Repo.Migrations.CreateEmailSubscriptions do
  use Ecto.Migration

  def change do
    create table(:email_subscriptions) do
      add :email, :string
      add :emailing_list_id, references(:emailing_lists)
      add :tenant, :string

      timestamps()
    end

    create unique_index(:email_subscriptions, [:emailing_list_id, :email], name: :email_subscriptions_emailing_list_id_email_index)
    create index(:email_subscriptions, [:email])
  end
end
