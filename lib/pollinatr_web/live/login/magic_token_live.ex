defmodule PollinatrWeb.Login.MagicTokenLive do
  use PollinatrWeb, :live_view
  import Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~L"""
      <div class="p-8">
        <div class="login relative text-6xl font-serif sm:mx-auto sm:max-w-none text-center pb-12">
          Welcome to the Slackies
        </div>
        <%= if @email_sent != true do %>
          <div class="mx-auto w-full sm:flex sm:items-center object-center sm:max-w-lg">
            <%= form_for :user, "#", [phx_submit: :save, autocomplete: "off", autocorrect: "off", autocapitalize: "off", spellcheck: "false", class: "w-full"], fn f -> %>
              <div class="sm:flex sm:items-center mb-6">
                <div class="sm:w-1/3">
                  <label class="block text-gray-100 font-bold sm:text-right mb-1 sm:mb-0 pr-4" for="user_nickname">Chat Name:</label>
                </div>
                <div class="sm:w-2/3">
                  <%= text_input f, :nickname, [class: "text-gray-900  min-w-full", placeholder: "Nickname", aria_required: "true"] %>
                </div>
              </div>
              <div class="sm:flex sm:items-center mb-6">
                <div class="sm:w-1/3">
                  <label class="block text-gray-100 font-bold sm:text-right mb-1 sm:mb-0 pr-4" for="user_email_address">Email Address:</label>
                </div>
                <div class="sm:w-2/3">
                  <%= email_input f, :email_address, [class: "text-gray-900 min-w-full", placeholder: "Email", aria_required: "true"] %>
                </div>
              </div>
              <div class="sm:flex sm:items-center">
                <div class="sm:w-1/3"></div>
                <div class="sm:w-2/3">
                  <%= submit "Submit", [class: "btn btn-default"] %>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="text-4xl ms-auto w-full text-center">
            Check your email for login links!
          </div>
        <% end %>
      </div>
    """
  end

  @impl true
  def mount(_params, %{"session_uuid" => key} = session, socket) do
    {:ok, assign(socket, email_sent: nil, key: key, return_to: session["return_to"] || "/")}
  end

  @impl true
  def handle_event(
        "save",
        %{"user" => %{"email_address" => email_address, "nickname" => nickname} = params},
        %{assigns: %{:return_to => return_to}} = socket
      ) do
    if Map.get(params, "form_disabled", nil) != "true" do
      case should_email(%{email_address: email_address}) do
        true ->
          Pollinatr.Helpers.Email.login_email(%{
            to: email_address,
            redirect_to: return_to || "/",
            nickname: nickname
          })
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
    limit = 4

    with true <-
           Pollinatr.Models.EmailingList.email_allowed(%{
             list_name: "login",
             address: email_address
           }),
         {:ok, _} <- ExRated.check_rate("magic_token_login_" <> email_address, 1_440_000, limit) do
      true
    else
      {:error, _limit} ->
        {:error, :rate_limit_exceeded}
    end
  end
end
