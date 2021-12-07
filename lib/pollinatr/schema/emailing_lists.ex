defmodule Pollinatr.Schema.EmailingLists do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emailing_lists" do
    field :name, :string
    field :description, :string
    field :subscription_type, Ecto.Enum, values: [:opt_in, :opt_out]
    field :tenant, :string

    timestamps()
  end

  @doc false
  def changeset(blocked_email, attrs) do
    blocked_email
    |> cast(attrs, [:email, :list_type, :tenant])
    |> validate_required([:email, :list_type])
  end
end
