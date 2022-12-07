defmodule Pollinatr.Schema.ChatLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "chat_log" do
    field :tenant_id, Ecto.UUID
    field :user_id, :integer

    field :message, :string

    timestamps()
  end

  @doc false
  def changeset(chat_log, attrs) do
    chat_log
    |> cast(attrs, [:tenant_id, :user_id, :message])
    |> validate_required([:tenant_id, :user_id, :message])
  end
end
