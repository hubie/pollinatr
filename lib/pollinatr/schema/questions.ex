defmodule Pollinatr.Schema.Questions do
  alias Pollinatr.Schema.{MultipleChoiceAnswers, Tenants}
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "questions" do
    belongs_to :tenant, Tenants, type: :binary_id
    field :sort_order, :integer
    field :question, :string
    field :answer_type, Ecto.Enum, values: [:multiple_choice]
    has_many :multiple_choice_answers, MultipleChoiceAnswers,
      foreign_key: :question_id

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
