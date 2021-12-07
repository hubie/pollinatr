defmodule PollinatrWeb.Login.AccessCodeLive do
  use PollinatrWeb, :live_view
  alias PollinatrWeb.LayoutView
  import Phoenix.HTML.Form
  import PollinatrWeb.Live.Helper, only: [signing_salt: 0]

  alias Pollinatr.User

  @impl true
  def render(assigns) do
    ~L"""
        <div class="login header">
          Welcome to the Slackies
        </div>
        <div class="login-box-container">
          <%= form_for :user, "#", [phx_submit: :save, autocomplete: "off", autocorrect: "off", autocapitalize: "off", spellcheck: "false"], fn f -> %>
            <fieldset class="flex flex-col md:w-full">

              <div>
                <label class="login access-code-label" for="form_email">Enter Access Code:</label>
                <%= text_input f, :validation_code, [class: "login password-box focus:border focus:border-b-0 rounded border", placeholder: "Access Code", aria_required: "true"] %>
                <%= submit "Submit" %>
              </div>
            </fieldset>
          <% end %>
        </div>
    </div>
    """
  end

  @impl true
  def mount(_params, %{"session_uuid" => key, "return_to" => return_to} = _session, socket) do
    {:ok, assign(socket, key: key, return_to: return_to)}
  end

  @impl true
  def mount(params, %{"session_uuid" => key} = _session, socket) do
    mount(params, %{"session_uuid" => key, "return_to" => "/"}, socket)
  end

  @impl true
  def handle_event(
        "save",
        %{"user" => %{"validation_code" => validation_code} = params},
        socket
      ) do
    if Map.get(params, "form_disabled", nil) != "true" do
      IO.inspect(validation_code, label: "VALIDATION_CODE")
      current_user =
        Pollinatr.Login.Form.get_user_by_code(validation_code)
        case current_user do
          %User{} ->
            send(self(), {:disable_form, current_user})
            {:noreply, assign(socket, user_id: current_user.id)}
          _ ->
            {:noreply, put_flash(socket, :error, "invalid code")}
        end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(
        {:disable_form, changeset},
        %{assigns: %{:key => key, :return_to => return_to}} = socket
      ) do
    case changeset do
      %User{id: user_id} ->
        insert_session_token(key, user_id)
        redirect = socket |> redirect(to: return_to)
        {:noreply, redirect}
      _ ->
        {:noreply, socket}
    end
  end

  def insert_session_token(key, user_id) do
    salt = signing_salt()
    token = Phoenix.Token.sign(PollinatrWeb.Endpoint, salt, user_id)
    :ets.insert(:auth_table, {:"#{key}", token})
  end
end
