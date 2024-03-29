defmodule Pollinatr.Results do
  use GenServer

  alias Pollinatr.Questions

  @initial_state %{
    results: [],
    ballots: %{},
    question: %{},
    voter_count: nil,
    show_mode: :show,
    message: nil,
    archived_results: %{},
    gsheet_archive_pid: nil
  }

  @max_votes 1

  @resultsTopic "results"
  @questionsTopic "questions"
  @metricsTopic "metrics"
  @showTopic "showControl"

  def start_link(args) do
    GenServer.start_link(__MODULE__, nil, args)
  end

  @impl true
  def init(_state) do
    state = @initial_state
    # state =
    #   case GSS.Spreadsheet.Supervisor.spreadsheet(System.get_env("VOTE_ARCHIVE_SHEET_ID", "")) do
    #     {:ok, pid} ->
    #       %{@initial_state | gsheet_archive_pid: pid}

    #     e ->
    #       IO.inspect(["Error initializing Archive Google Sheet, going without it", e])
    #       @initial_state
    #   end

    {:ok, state}
  end

  @impl true
  def handle_cast(:reset_results, state) do
    new_state = archive_results(state)
    broadcast_voting_closed()
    # broadcast_results(%{}, new_state.results)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        %{new_question: %{id: id}},
        state
      ) do
    if %{} != state.question, do: archive_results(state)
    new_question = GenServer.call(Questions, %{get_question: id})
    clean_results = Enum.map(new_question.answers, fn a -> %{a => 0} end)
    broadcast_question(new_question)
    broadcast_results(new_question, clean_results)
    {:noreply, %{state | results: clean_results, question: new_question, ballots: %{}}}
  end

  @impl true
  def handle_cast(%{set_message: message}, state) do
    broadcast_message(%{message: message})
    {:noreply, %{state | message: message}}
  end

  @impl true
  def handle_cast(%{new_voter_count: voter_count}, state) do
    new_state = %{state | voter_count: voter_count}
    broadcast_metrics(%{voter_count: voter_count})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(%{set_show_mode: mode}, state) do
    broadcast_message(%{message: nil})
    new_state = %{state | show_mode: mode, message: nil}
    broadcast_show_mode(%{show_mode: mode})
    {:noreply, new_state}
  end

  @impl true
  def handle_call(%{voter_id: voter_id, vote_cast: _} = ballot, _from, state) do
    votes_for_voter = get_vote_count_for_voter(voter_id, state)

    cond do
      votes_for_voter < @max_votes ->
        new_state = tally_vote(ballot, state)
        broadcast_results(state.question, new_state.results)

        if votes_for_voter + 1 < @max_votes do
          {:reply, %{voter_state: :new_question}, new_state}
        else
          {:reply, %{voter_state: :voted}, new_state}
        end

      true ->
        {:reply, %{voter_state: :voted}, state}
    end
  end

  @impl true
  def handle_call(%{get_voter_state: voter_id}, _from, state) do
    vote_count = get_vote_count_for_voter(voter_id, state)

    voter_state =
      cond do
        %{} == state.question -> :voting_closed
        vote_count >= @max_votes -> :voted
        true -> :new_question
      end

    {:reply, voter_state, state}
  end

  @impl true
  def handle_call(:get_current_results, _from, state) do
    {:reply, %{question: state.question, results: state.results}, state}
  end

  @impl true
  def handle_call(:get_show_state, _from, state) do
    {:reply, %{show_mode: state.show_mode, message: state.message}, state}
  end

  @impl true
  def handle_call(:get_current_question, _from, state) do
    {:reply, state.question, state}
  end

  @impl true
  def handle_call(:get_current_voter_count, _from, state) do
    {:reply, state.voter_count, state}
  end

  defp broadcast_message(%{message: message}) do
    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      @showTopic,
      {__MODULE__, %{message: message}}
    )
  end

  defp get_vote_count_for_voter(voter_id, state) do
    (get_in(state, [:ballots, voter_id]) || []) |> Enum.count()
  end

  defp tally_vote(%{voter_id: voter_id, vote_cast: vote}, state) do
    new_results =
      Enum.map(state.results, fn x ->
        if Map.has_key?(x, vote), do: %{vote => x[vote] + 1}, else: x
      end)

    {_, new_ballots} =
      Map.get_and_update(state.ballots, voter_id, fn current_value ->
        {current_value, (current_value || []) ++ [vote]}
      end)

    new_state = %{state | results: new_results, ballots: new_ballots}
    new_state
  end

  defp archive_results(
         %{
           results: results,
           question: %{question: question, id: id},
           archived_results: archived_results,
           gsheet_archive_pid: _pid
         } = state
       ) do
    new_archive = Map.put(archived_results, id, %{results: results, question: question})

    # time = DateTime.now("Etc/UTC") |> elem(1) |> to_string

    # stripped_results =
    #   for rs <- results, {a, v} <- rs do
    #     [a, v]
    #   end
    #   |> List.flatten()

    # gsrow = [time, question] ++ stripped_results
    # IO.inspect(gsrow, label: "Writing Google Sheet Row")
    # GSS.Spreadsheet.append_row(pid, 1, gsrow)

    IO.inspect([new_archive, label: "RESULT_ARCHIVE"])
    %{state | results: [], question: %{}, archived_results: new_archive}
  end

  defp archive_results(state) do
    IO.inspect(state, label: "Invalid archive_results request")
    state
  end

  defp broadcast_results(question, results) do
    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      @resultsTopic,
      {__MODULE__, %{question: question, results: results}}
    )
  end

  defp broadcast_question(question) do
    IO.inspect(question, label: "broadcasting")

    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      @questionsTopic,
      {__MODULE__, %{new_question: question, voter_state: :new_question}}
    )
  end

  defp broadcast_voting_closed() do
    Phoenix.PubSub.broadcast(Pollinatr.PubSub, @questionsTopic, {__MODULE__, :voting_closed})
  end

  defp broadcast_metrics(metrics) do
    Phoenix.PubSub.broadcast(
      Pollinatr.PubSub,
      @metricsTopic,
      {__MODULE__, %{online_voters: metrics.voter_count}}
    )
  end

  defp broadcast_show_mode(mode) do
    Phoenix.PubSub.broadcast(Pollinatr.PubSub, @showTopic, {__MODULE__, mode})
  end

  def vote_cast(voter_id, answer) do
    GenServer.call(__MODULE__, %{voter_id: voter_id, vote_cast: answer})
  end

  def reset_results() do
    GenServer.cast(__MODULE__, :reset_results)
  end

  def get_current_results() do
    GenServer.call(__MODULE__, :get_current_results)
  end

  def get_current_question() do
    GenServer.call(__MODULE__, :get_current_question)
  end

  def get_current_voter_count() do
    GenServer.call(__MODULE__, :get_current_voter_count)
  end

  def new_question(question) do
    GenServer.cast(__MODULE__, %{new_question: question})
  end

  def update_user_count(new_count) do
    GenServer.cast(__MODULE__, %{new_voter_count: new_count})
  end

  def get_voter_state(voter_id) do
    GenServer.call(__MODULE__, %{get_voter_state: voter_id})
  end

  def set_show_mode(%{show_mode: mode}) do
    GenServer.cast(__MODULE__, %{set_show_mode: mode})
  end

  def send_message(%{message: message}) do
    GenServer.cast(__MODULE__, %{set_message: message})
  end
end
