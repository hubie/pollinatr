defmodule PollinatrWeb.Login.MagicTokenLive do
  use PollinatrWeb, :live_view
  alias PollinatrWeb.LayoutView
  import Phoenix.HTML.Form

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
                <label class="login access-code-label" for="form_email">Enter Email Address:</label>
                <%= email_input f, :email_address, [class: "login password-box focus:border focus:border-b-0 rounded border", placeholder: "Email", aria_required: "true"] %>
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
        %{"user" => %{"email_address" => email_address} = params},
        %{assigns: %{:return_to => return_to}} = socket
      ) do

    if Map.get(params, "form_disabled", nil) != "true" do
      Pollinatr.Helpers.Email.login_email(%{to: email_address, redirect_to: return_to  || "/"})
        |> Pollinatr.Helpers.Mailer.deliver()
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
end
