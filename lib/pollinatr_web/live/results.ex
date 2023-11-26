defmodule PollinatrWeb.Results do
  use Phoenix.LiveView

  alias Pollinatr.Results

  @topic inspect(__MODULE__)
  @resultsTopic "results"

  def subscribe do
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @topic)
    Phoenix.PubSub.subscribe(Pollinatr.PubSub, @resultsTopic)
  end

  @initial_store %{
    question: %{},
    results: [],
    params: %{}
  }

  def mount(params, _session, socket) do
    if connected?(socket), do: subscribe()

    case Results.get_current_results() do
      %{question: %{question: question}, results: results} ->
        new_socket = push_event(socket, "new_results", %{data: formatResults(results)})

        {:ok,
         assign(new_socket, :state, %{
           @initial_store
           | question: %{question: question},
             results: results,
             params: params
         })}

      %{question: %{}, results: []} ->
        new_socket = push_event(socket, "new_results", %{data: %{}})

        {:ok,
         assign(new_socket, :state, %{@initial_store | question: %{}, results: [], params: params})}

      cr ->
        IO.inspect(["Unexpected current results: ", cr])
    end
  end

  def handle_info(
        {Results, %{question: question, results: results} = _update},
        %{assigns: %{state: state}} = socket
      ) do
    new_socket = push_event(socket, "new_results", %{data: formatResults(results)})

    new_state = %{state | results: results, question: question}
    {:noreply, assign(new_socket, :state, new_state)}
  end

  defp formatResults(results) do
    results
  end

  def render(assigns) do
    case assigns.state.params do
      %{"view" => "headline"} ->
        Phoenix.View.render(PollinatrWeb.Results.Results, "headline_live.html", assigns)

      _ ->
        ~H"""
        <div class="resultscontainer">
          <PollinatrWeb.Components.ResultsComponent.showResults />
        </div>
        """
    end
  end
end
