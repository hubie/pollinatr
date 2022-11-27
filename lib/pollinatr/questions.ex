defmodule Pollinatr.Questions do
  use GenServer
  require Ecto.Query
  alias Pollinatr.Repo
  alias Pollinatr.Schema.{Questions}

  @initial_state %{
    questions: []
  }

  # @metricsIngestion inspect(Pollinatr.Metrics)

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
  def handle_call(%{get_questions: :all, tenant_id: tenant_id}, _from, state) do
    questions = Repo.all(
      Ecto.Query.from(
        q in Questions,
        order_by: [asc: :sort_order],
        preload: :multiple_choice_answers),
      tenant_id: tenant_id
      )
    {:reply, Enum.map(questions, fn q -> format_question(q) end), state}
  end

  @impl true
  def handle_call(%{get_question: id}, _from, state) do
    question = Repo.one(
      Ecto.Query.from(
        q in Questions,
        where: q.id == ^id,
        preload: :multiple_choice_answers),
      skip_tenant_id: true
      )
    {:reply, format_question(question), state}
  end

  defp format_question(%Questions{id: id, tenant_id: tenant_id, question: question, multiple_choice_answers: answers}) do
    %{
      id: id,
      tenant_id: tenant_id,
      question: question,
      answers: answers |> Enum.map(fn a -> a.answer end)
    }
  end
end
