defmodule Pollinatr.Schema.EmailSubscriptions do
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_subscriptions" do
    field :email, :string
    field :emailing_list_id, :integer
    field :tenant, :string

    timestamps()
  end

  @doc false
  def changeset(blocked_email, attrs) do
    blocked_email
    |> cast(attrs, [:email, :emailing_list_id, :tenant])
    |> validate_required([:email, :emailing_list_id])
    |> unique_constraint(:email_emailing_list_id,
      name: :email_subscriptions_emailing_list_id_email_index
    )
  end
end
