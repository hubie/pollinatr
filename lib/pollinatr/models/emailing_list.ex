defmodule Pollinatr.Models.EmailingList do
  import Ecto.Query
  alias Pollinatr.Repo
  alias Pollinatr.Schema.{EmailingLists, EmailSubscriptions}

  def email_allowed(%{list_name: list_name, address: email}) do
    query =
      from s in EmailSubscriptions,
        join: l in EmailingLists,
        on: s.emailing_list_id == l.id,
        where: s.email == ^email,
        where: l.name == ^list_name,
        where: l.subscription_type == :opt_out,
        select: s

    case Repo.one(query) do
      nil ->
        true

      %{} ->
        false

      other ->
        IO.inspect(other, label: "got a strange result during subscription check")
    end
  end

  def remove(%{list_name: list_name, email: email}) do
    case get_list(%{list_name: list_name}) do
      nil ->
        {:error, :no_list_found}

      %{id: list_id, subscription_type: :opt_out} ->
        changeset =
          EmailSubscriptions.changeset(%EmailSubscriptions{}, %{
            email: email,
            emailing_list_id: list_id
          })

        Repo.insert(changeset)

      %{} ->
        {:error, :unsupported_subscription_type}
    end
  end

  defp get_list(%{list_name: list_name}) do
    Repo.one(
      from l in EmailingLists,
        where: l.name == ^list_name,
        select: l
    )
  end
end
