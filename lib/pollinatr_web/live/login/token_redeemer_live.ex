defmodule PollinatrWeb.Login.TokenRedeemer do
  use PollinatrWeb, :live_view
  import PollinatrWeb.Live.Helper, only: [signing_salt: 0]
  alias Pollinatr.Helpers.Tokens
  alias PollinatrWeb.Router.Helpers, as: Routes
  alias PollinatrWeb.Endpoint
  alias Pollinatr.Models.User

  @impl true
  def render(assigns) do
    ~L"""
        <div class="login header">
          Logging you in!
        </div>
    """
  end

  @impl true
  def mount(params, %{"session_uuid" => key} = _session, socket) do
    case Tokens.decrypt(:magic_token, params["token"] || "") do
      {:ok, %{email_address: email_address} = payload} ->
        IO.inspect(payload, label: "PAYLOAD")

        current_user =
          User.find_or_create_user(%{
            email_address: email_address,
            nickname: get_in(payload, [:nickname]),
            role: :voter
          })

        insert_session_token(key, current_user.id)

        {:ok, push_redirect(socket, to: Map.get(payload, :redirect_to, "/"))}

      {:error, _} ->
        {:ok,
         socket
         |> push_redirect(to: Routes.login_path(Endpoint, :index))
         |> put_flash(:error, "Invalid login token")}
    end
  end

  def insert_session_token(key, user_id) do
    salt = signing_salt()
    token = Phoenix.Token.sign(Endpoint, salt, user_id)
    :ets.insert(:auth_table, {:"#{key}", token})
  end
end
