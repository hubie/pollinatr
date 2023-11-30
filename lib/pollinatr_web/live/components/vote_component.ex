defmodule PollinatrWeb.Components.VoteComponent do
  use Phoenix.Component

  def votePanel(assigns) do
    ~H"""
    <%= if @message != nil do %>
      <div class="message"><%= @message %></div>
    <% end %>

    <%= case @show_mode do %>
      <% :preshow -> %>

        <div class="lg:text-6xl md:text-4xl sm:text-2xl font-extrabold pb-4">Welcome to the 2023 Slackies!</div>
        <div class="font-normal lg:text-lg space-y-4">
        <p/>
        The winners for some categories will be chosen by you lovely people!
        The nominees will be introduced, and when it's time to place your vote, buttons to select the nominees will automatically appear – right here!
        <p/>
        Is it bringing power to the people or complete anarchy?  Whatever it is, it's happening!
        </div>
      <% :show -> %>
        <%= case @voter_state do %>
          <% :voting_closed -> %>
                Suspenseful Music Playing<span class="ellipsis-anim"><span>.</span><span>.</span><span>.</span></span>
          <% :voted -> %>
            <div class="lg:text-6xl md:text-4xl sm:text-2xl font-extrabold text-center space-y-4">
              Your vote has been counted!
              <br/>
              <i class="fas fa-vote-yea vote-counted"></i>
            </div>
          <% :new_question -> %>
            <PollinatrWeb.Components.QuestionComponent.ask question={@question} />
            <% _ -> %>
              <%= "Unknown state: #{@voter_state}" %>
          <% end %>
        <% :postshow -> %>
          <div class="lg:text-6xl md:text-4xl sm:text-2xl font-extrabold pb-4 text-center">
            We hope you enjoyed the show!
          </div>
       <% _ ->  %>
        <%= "Unknown show state #{inspect(@show_mode)}" %>
      <% end %>

    """
  end
end
