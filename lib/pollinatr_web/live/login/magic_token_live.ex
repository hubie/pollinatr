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
      <%= if @email_sent != true do %>
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
      <% else %>
        <div class="email-sent-container">
          Check your email for login links!
        </div>
      <% end %>

    """
  end

  @impl true
  def mount(_params, %{"session_uuid" => key} = session, socket) do
    {:ok, assign(socket, email_sent: nil, key: key, return_to: session["return_to"] || "/")}
  end

  @impl true
  def handle_event(
        "save",
        %{"user" => %{"email_address" => email_address} = params},
        %{assigns: %{:return_to => return_to}} = socket
      ) do
    if Map.get(params, "form_disabled", nil) != "true" do
      case should_email(%{email_address: email_address}) do
        true ->
          Pollinatr.Helpers.Email.login_email(%{to: email_address, redirect_to: return_to || "/"})
          |> Pollinatr.Helpers.Mailer.deliver()

          socket =
            socket
            |> put_flash(:info, "Email sent to " <> email_address)
            |> assign(email_sent: true)

          {:noreply, socket}

        false ->
          {:noreply, put_flash(socket, :error, "Unsubscribed")}

        {:error, _} ->
          socket = socket |> put_flash(:error, "Too many attempts")
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  defp should_email(%{email_address: email_address}) do
    cond do
      Pollinatr.Models.EmailingList.email_allowed(%{list_name: "login", address: email_address}) ==
          false ->
        false

      {:ok, _} = ExRated.check_rate("magic_token_login_" <> email_address, 1_440_000, 2) ->
        true

      true ->
        false
    end
  end
end
