defmodule Pollinatr.Schema.MultipleChoiceAnswers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "multiple_choice_answers" do
    field :tenant_id, Ecto.UUID
    field :question_id, Ecto.UUID
    field :sort_order, :integer
    field :answer, :string

    timestamps()
  end

  @doc false
  def changeset(multiple_choice_answer, attrs) do
    multiple_choice_answer
    |> cast(attrs, [:tenant_id, :question_id, :sort_order, :answer])
    |> validate_required([:tenant_id, :question_id, :sort_order, :answer])
    |> unique_constraint([:tenant_id, :question_id, :sort_order])
  end
end
