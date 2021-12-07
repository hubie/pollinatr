defmodule PollinatrWeb.UnsubscribeController do
  use PollinatrWeb, :controller
  alias Pollinatr.Helpers.Tokens
  alias Pollinatr.Repo
  alias Pollinatr.Models.EmailingList

  def index(conn, params) do
    max_age =
      Application.fetch_env!(:pollinatr, PollinatrWeb.Endpoint)[:unsubscribe_link_lifespan]

    case Tokens.decrypt(:magic_token, params["token"] || "", max_age) do
      {:ok, %{email_address: email_address, list_name: list_name} = payload} ->
        case EmailingList.remove(%{email: email_address, list_name: list_name}) do
          {:ok, _} ->
            render(conn, "success.html", list_type: list_name)

          {:error, %{errors: [email_emailing_list_id: message]}} ->
            render(conn, "failure.html", reason: "Already unsubscribed")

          {:error, reason} ->
            render(conn, "failure.html", reason: to_string(reason))
        end

      {:error, :expired} ->
        render(conn, "failure.html", reason: "Link expired")

      {:error, _} ->
        render(conn, "failure.html", reason: nil)
    end
  end
end
