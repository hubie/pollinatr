defmodule PollinatrWeb.VoterLive do
  use Phoenix.LiveView

  alias Pollinatr.Presence
  alias Pollinatr.Results

  @topic inspect(__MODULE__)
  @metricsTopic inspect(Pollinatr.Metrics)
  @questionTopic "questions"
  @showTopic "showControl"

  def subscribe do
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @topic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @questionTopic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @showTopic)
  end

  @initial_store %{
    embed: false,
    question: %{},
    online_user_count: 0,
    session_id: nil,
    voter_state: :new,
    show_mode: nil,
    message: ""
  }

  def mount(:not_mounted_at_router, session, socket) do
    mount(%{"embed": "true"}, session, socket)
  end

  def mount(params, %{"session_uuid" => key} = _session, socket) do
    if connected?(socket), do: subscribe()

    Presence.track(
      self(),
      @metricsTopic,
      socket.id,
      %{}
    )

    embed = Map.get(params, "embed", "false")

    %{show_mode: show_mode, message: message} = GenServer.call(Results, :get_show_state)

    {:ok, assign(socket, %{@initial_store |
      embed: embed,
      question: Results.get_current_question(),
      session_id: key,
      voter_state: Results.get_voter_state(key),
      show_mode: show_mode,
      message: message
      })
    }
  end

  def handle_info({Results, :voting_closed}, state) do
    new_state = state
      |> update(:question, fn _ -> %{} end)
      |> update(:voter_state, fn _ -> :voting_closed end)

    {:noreply, new_state}
  end

  def handle_info({Results, %{show_mode: mode}}, state) do
    new_state = state
      |> update(:show_mode, fn _ -> mode end)

    {:noreply, new_state}
  end

  def handle_info({Results, %{message: message}}, state) do
    new_state = state
      |> update(:message, fn _ -> message end)

    {:noreply, new_state}
  end

  def handle_info({Results, %{new_question: question, voter_state: new_voter_state}}, state) do
    new_state = state
      |> update(:question, fn _ -> question end)
      |> update(:voter_state, fn _ -> new_voter_state end)

    new_state = case Map.get(question, :time_limit) do
      nil -> push_event(new_state, "no_timer", %{})
      limit -> push_event(new_state, "new_timer", %{data: limit})
    end

    {:noreply, new_state}
  end

  def handle_event("submitAnswer", %{"value" => value}, socket) do
    %{voter_state: new_voter_state} = Results.vote_cast(socket.assigns.session_id, value)
    new_socket = socket
      |> update(:voter_state, fn _ -> new_voter_state end)

    {:noreply, new_socket}
  end
end
