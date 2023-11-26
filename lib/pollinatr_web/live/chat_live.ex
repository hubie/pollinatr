defmodule PollinatrWeb.ChatLive do
  use Phoenix.LiveView

  # alias PollinatrWeb.Components.ChatboxComponent
  alias Pollinatr.Models.EmailingList
  # alias Pollinatr.Presence
  alias Pollinatr.Chat.Chat
  alias Pollinatr.Chat.Message
  alias Pollinatr.Repo
  alias Pollinatr.Schema.ChatLog
  alias Pollinatr.Schema.Users

  @topic inspect(__MODULE__)
  @chatTopic "chat"

  def subscribe(%{user_id: user_id} = _params) do
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @topic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @chatTopic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, get_topic_for_user(user_id))
  end

  @initial_store %{
    embed: false,
    session_id: nil,
    user_id: nil,
    tenant_id: nil,
    username: nil,
    role: nil,
    messages: [],
    nickname: nil,
    new_message_form: Chat.new_message(%ChatLog{}) |> to_form()
  }

  def mount(:not_mounted_at_router, session, socket) do
    mount(%{embed: "true"}, session, socket)
  end

  def mount(
        params,
        %{"session_uuid" => key, "user_id" => user_id, "tenant_id" => tenant_id} = session,
        socket
      ) do
    if connected?(socket), do: subscribe(%{user_id: user_id})

    # Presence.track(
    #   self(),
    #   @metricsTopic,
    #   socket.id,
    #   %{}
    # )
    embed = Map.get(params, "embed", "false")
    IO.inspect(session, label: "CHAT SESSION")
    user = Repo.get_by(Users, [id: user_id], tenant_id: tenant_id)

    {:ok,
     assign(socket, %{
       @initial_store
       | embed: embed,
         session_id: key,
         user_id: user.id,
         tenant_id: tenant_id,
         username: if(user.role == :admin, do: "Admin", else: user.email_address),
         role: user.role,
         nickname:
           if(user.role == :admin, do: "Admin", else: user.nickname || user.email_address),
         messages: Enum.reverse(Chat.get_recent_messages())
     }), temporary_assigns: [messages: []]}
  end

  defp get_topic_for_user(user_id) do
    "user:#{user_id}"
  end

  def handle_event("save", %{"chat_log" => %{"message" => ""}}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"chat_log" => %{"message" => message}}, socket) do
    Chat.send_message(%Message{
      tenant_id: socket.assigns.tenant_id,
      message: message,
      session_id: socket.assigns.session_id,
      user_id: socket.assigns.user_id,
      username: socket.assigns.username,
      nickname: socket.assigns.nickname
    })

    {:noreply, assign(socket, message: message)}
  end

  def handle_event("ban-user", %{"userid" => user_id} = _params, socket) do
    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      get_topic_for_user(user_id),
      {:user_management, %{operation: :ban}}
    )

    IO.inspect("users_socket:#{user_id}", label: "Kicking user:")

    {:noreply, socket}
  end

  def handle_info({:user_management, %{operation: :ban}}, socket) do
    user_id = socket.assigns.user_id
    session_id = socket.assigns.session_id

    IO.inspect(%{user_id: user_id, session_id: session_id}, label: "Committing seppuku")
    PollinatrWeb.Endpoint.broadcast("users_socket:#{user_id}", "disconnect", %{})
    EmailingList.remove(%{email: user_id, list_name: "login"})
    :ets.delete(:auth_table, :"#{session_id}")

    # TODO: this doesn't work because our session probably died already from the 'disconnect' message above
    {:noreply, redirect(socket, to: "/login")}
  end

  def handle_info({Chat, {:new_message, message}}, socket) do
    IO.inspect(["NEW MESSSAGE", message])
    {:noreply, assign(socket, :messages, [message])}
  end

  def handle_info(msg, socket) do
    IO.inspect(msg, label: "Unhandled message")
    {:noreply, socket}
  end

  attr :field, Phoenix.HTML.FormField
  attr :rest, :global, include: ~w(type)

  def input(assigns) do
    ~H"""
    <input id={@field.id} name={@field.name} value={@field.value} {@rest} />
    """
  end

  def render(assigns) do
    ~H"""
    <div class="content-body">
      <div class="chat-container">
        <div class="chat-box" id="chat-box" phx-update="append">
          <%= for %{user_id: user_id, username: username, nickname: nickname, message: message, index: id} <- @messages do %>
            <div class="chat-message" id={"chat-message-#{id}"}>
              <span class="chat-message sender" title={username}><%= nickname %></span>
                <span :if={@role == :admin} class="ban-user-sigil" title={"Kick and Ban user_id #{user_id}"} phx-click="ban-user" phx-value-userid={user_id}>🚫</span>
              <br/>
              <span class="chat-message message"><%= message %></span>
            </div>
          <% end %>
        </div>

        <div class="compose-message-box">
          <.form
            for={@new_message_form}
            phx-submit="save"
          >
            <.input field={@new_message_form[:message]} placeholder="Message" class="send-message-input" />
            <button type="submit" class="send-message-submit">
              <i class="fas fa-paper-plane fa-lg"/>
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
