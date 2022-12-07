defmodule Pollinatr.Chat.Chat do
  use GenServer
  alias Pollinatr.Chat.Message
  alias Pollinatr.Repo
  alias Pollinatr.Schema.ChatLog

  @chatTopic "chat"

  @initial_state %{
    messages: []
  }

  def start_link(args) do
    GenServer.start_link(__MODULE__, nil, args)
  end

  def subscribe do
    # Phoenix.PubSub.subscribe(Pollinatr.PubSub, @metricsIngestion)
  end

  @impl true
  def init(_state) do
    subscribe()
    {:ok, @initial_state}
  end

  @impl true
  def handle_cast({:send_message, %Message{} = new_message}, %{messages: messages} = state) do
    last_index = List.first(messages, %{index: 0}).index
    new_message = %{new_message | timestamp: :os.system_time(:millisecond), index: last_index + 1}
    IO.inspect([new_message | messages])
    broadcast_new_message(new_message)

    add_to_chat_log(new_message)

    {:noreply, %{state | messages: [new_message | messages]}}
  end

  @impl true
  def handle_call({:get_recent_messages, count}, _from, %{messages: messages} = state) do
    {:reply, Enum.take(messages, count), state}
  end

  defp broadcast_new_message(%Message{} = message) do
    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      @chatTopic,
      {__MODULE__, {:new_message, message}}
    )
  end

  def send_message(%Message{} = message) do
    GenServer.cast(__MODULE__, {:send_message, message})
  end

  def get_recent_messages(count \\ 25) do
    GenServer.call(__MODULE__, {:get_recent_messages, count})
  end

  defp add_to_chat_log(%Message{tenant_id: tenant_id, user_id: user_id, message: message} = _message) do
    changeset =
      ChatLog.changeset(%ChatLog{}, %{
        tenant_id: tenant_id,
        user_id: user_id,
        message: message
      })

    Repo.insert(changeset)
  end
end
