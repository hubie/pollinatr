defmodule Pollinatr.Schema.Tenants do
  use Ecto.Schema
  import Ecto.Changeset
  alias Pollinatr.Schema.Questions

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "tenants" do
    field :name, :string
    has_many :questions, Questions, foreign_key: :tenant_id

    timestamps()
  end

  @doc false
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
