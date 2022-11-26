defmodule Pollinatr.Schema.Users do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :tenant_id, Ecto.UUID
    field :email_address, :string
    field :nickname, :string
    field :role, Ecto.Enum, values: [:admin, :voter]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:tenant_id, :email_address, :nickname, :role])
    |> validate_required([:tenant_id, :email_address, :role])
    |> unique_constraint([:tenant_id, :email_address])
  end
end
