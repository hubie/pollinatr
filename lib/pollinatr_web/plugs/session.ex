defmodule PollinatrWeb.Plug.Session do
  import Plug.Conn, only: [get_session: 2, put_session: 3, halt: 1, assign: 3]
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  import PollinatrWeb.Live.Helper, only: [signing_salt: 0]


  def redirect_unauthorized(conn, [resource: resource] = _opts) do
    user_id = Map.get(conn.assigns, :user_id)
    role = Map.get(conn.assigns, :role)

    cond do
      :ok == Bodyguard.permit(Pollinatr.User, resource, %{user_id: user_id}) ->
        conn
      true ->
        conn
          |> put_flash(:info, "Unauthorized")
          |> put_session(:return_to, conn.request_path)
          |> redirect(to: PollinatrWeb.Router.Helpers.login_path(conn, :index))
          |> halt()
    end
  end

  def validate_session(conn, _opts) do
    case get_session(conn, :session_uuid) do
      nil ->
        conn
        |> put_session(:session_uuid, UUID.uuid4())

      session_uuid ->
        conn
        |> validate_session_token(session_uuid)
    end
  end

  def validate_session_token(conn, session_uuid) do
    case :ets.lookup(:auth_table, :"#{session_uuid}") do
      [{_, token}] ->
        case Phoenix.Token.verify(PollinatrWeb.Endpoint, signing_salt(), token,
               max_age: 806_400
             ) do
          {:ok, user_id} ->
            conn
              |> assign(:user_id, user_id)
              |> put_session("user_id", user_id)
          {:ok, %{type: :email, email_address: email_address}} ->
            conn
              |> assign(:email_address, email_address)
              |> put_session("email_address", email_address)
          {:ok, %{type: :validation_code, validation_code: validation_code}} ->
            conn
              |> assign(:validation_code, validation_code)
              |> put_session("validation_code", validation_code)
          _ ->
            conn
        end

      _ ->
        conn
    end
  end
end
