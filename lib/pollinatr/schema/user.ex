defmodule Pollinatr.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Enum

  schema "users" do
    field :email_address, :string
    field :nickname, :string
    field :role, Ecto.Enum, values: [:admin, :voter]

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email_address, :nickname, :role])
    |> validate_required([:email_address, :role])
    |> unique_constraint(:email_address)
  end
end
