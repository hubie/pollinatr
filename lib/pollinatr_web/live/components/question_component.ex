defmodule PollinatrWeb.Components.QuestionComponent do
  use Phoenix.Component

  def ask(assigns) do
    ~H"""
    <h1 class="question text-4xl font-sans font-extrabold pb-4">
      <%= get_in(@question, [:question]) %>
    </h1>
    <div class="voter answers">
      <%= for answer <- get_in(@question, [:answers]) || [] do %>
        <button phx-click="submitAnswer" class="btn btn-vote text-2xl" value={answer}><%= answer %></button>
      <% end %>
    </div>
    <div id="countdownTimer" phx-hook="Timer"></div>
    """
  end
end
