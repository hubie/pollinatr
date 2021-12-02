defmodule PollinatrWeb.Login.TokenRedeemer do
  use PollinatrWeb, :live_view
  alias PollinatrWeb.LayoutView
  import Phoenix.HTML.Form
  import PollinatrWeb.Live.Helper, only: [signing_salt: 0]
  alias Pollinatr.Helpers.Tokens
  alias PollinatrWeb.Router.Helpers, as: Routes
  alias PollinatrWeb.Endpoint
  alias Pollinatr.User

  @impl true
  def render(assigns) do
    ~L"""
        <div class="login header">
          Logging you in!
        </div>
    """
  end

  @impl true
  def mount(%{"token" => token} = _params, %{"session_uuid" => key} = _session, socket) do
    case Tokens.decrypt(:magic_token, token) do
      {:ok, %{email_address: email_address} = payload} ->
        current_user = User.get_user(%{email_address: email_address})
        insert_session_token(key, current_user.id)

        assign(socket, key: key, user_id: current_user.id)
        redirect = socket |> push_redirect(to: Map.get(payload, :redirect_to, "/"))
        {:ok, redirect}
      {:error, _} ->
        put_flash(socket, :error, "Invalid login token")
        {:ok, socket |> push_redirect(to: Routes.login_path(Endpoint, :index))}
    end
  end

  def mount(_params, _session, socket) do
      put_flash(socket, :error, "Missing token")
      {:ok, socket |> push_redirect(to: Routes.login_path(Endpoint, :index))}
  end

  def insert_session_token(key, user_id) do
    salt = signing_salt()
    token = Phoenix.Token.sign(Endpoint, salt, user_id)
    :ets.insert(:auth_table, {:"#{key}", token})
  end
end
