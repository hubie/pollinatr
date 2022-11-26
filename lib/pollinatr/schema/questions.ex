defmodule Pollinatr.Schema.Questions do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "question" do
    field :tenant_id, Ecto.UUID
    field :sort_order, :integer
    field :question, :string
    field :answer_type, Ecto.Enum, values: [:multiple_choice]

    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:tenant_id, :sort_order, :question, :answer_type])
    |> validate_required([:tenant_id, :sort_order, :question, :answer_type])
    |> unique_constraint([:tenant_id, :sort_order])
  end
end
