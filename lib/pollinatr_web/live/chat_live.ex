defmodule PollinatrWeb.ChatLive do
  use Phoenix.LiveView
  import Phoenix.LiveView.Helpers
  import Phoenix.HTML.Form
  alias PollinatrWeb.Components.ChatboxComponent

  alias Pollinatr.Presence
  alias Pollinatr.Chat.Chat
  alias Pollinatr.Chat.Message

  @topic inspect(__MODULE__)
  @chatTopic "chat"

  def subscribe do
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @topic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @chatTopic)
  end

  @initial_store %{
    embed: false,
    session_id: nil,
    user_id: nil,
    messages: [],
    nickname: nil
  }

  def mount(:not_mounted_at_router, session, socket) do
    mount(%{embed: "true"}, session, socket)
  end

  def mount(params, %{"session_uuid" => key, "user_id" => user_id} = _session, socket) do
    if connected?(socket), do: subscribe()

    # Presence.track(
    #   self(),
    #   @metricsTopic,
    #   socket.id,
    #   %{}
    # )
    embed = Map.get(params, "embed", "false")
    user = Pollinatr.Models.User.get_user(%{user_id: user_id})

    {:ok,
     assign(socket, %{
       @initial_store
       | embed: embed,
         session_id: key,
         user_id: if(user.role == :admin, do: "Admin", else: user.email_address),
         nickname:
           if(user.role == :admin, do: "Admin", else: user.nickname || user.email_address),
         messages: Enum.reverse(Chat.get_recent_messages())
     }), temporary_assigns: [messages: []]}
  end

  def handle_event("save", %{"send_message" => %{"message" => ""}}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"send_message" => %{"message" => message}}, socket) do
    Chat.send_message(%Message{
      message: message,
      session_id: socket.assigns.session_id,
      user_id: socket.assigns.user_id,
      nickname: socket.assigns.nickname
    })

    {:noreply, assign(socket, message: message)}
  end

  def handle_info({Chat, {:new_message, message}}, socket) do
    {:noreply, assign(socket, :messages, [message])}
  end

  def render(assigns) do
    ~L"""
    <div class="content-body">
      <div class="chat-container">
        <div class="chat-box" id="chat-box" phx-update="append">
          <%= for %{user_id: sender, nickname: nickname, message: message, index: id} <- @messages do %>
            <div class="chat-message" id="chat-message-<%= id %>">
              <span class="chat-message sender" title="<%= sender %>"><%= nickname %></span><br/><span class="chat-message message"><%= message %></span>
            </div>
          <% end %>
        </div>

        <div class="compose-message-box">
          <%= m = form_for :send_message, "#", [phx_submit: :save, class: "send-message-form"] %>
              <%= text_input m, :message, [placeholder: "Message", id: :submit_message, class: "send-message-input", phx_hook: "MessageSubmit"] %>
              <%= submit [class: "send-message-submit"] do %>
                <i class="fas fa-paper-plane fa-lg"></i>
              <% end %>
          </form>
        </div>
      </div>
    </div>
    """
  end
end
