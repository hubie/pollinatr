defmodule PollinatrWeb.Components.VoteComponent do
  use Phoenix.Component

  def votePanel(assigns) do
    ~H"""
    <%= if @message != nil do %>
      <div class="message"><%= @message %></div>
    <% end %>

    <%= case @show_mode do %>
      <% :preshow -> %>
        <h2>Welcome to the 2023 Slackies!</h2>
        <p/>
        The winners for some categories will be chosen by you lovely people!
        The nominees will be introduced, and when it's time to place your vote, buttons to select the nominees will automatically appear – right here!
        <p/>
        Is it bringing power to the people or complete anarchy?  Whatever it is, it's happening!
      <% :show -> %>
        <%= case @voter_state do %>
          <% :voting_closed -> %>
                Suspenseful Music Playing<span class="ellipsis-anim"><span>.</span><span>.</span><span>.</span></span>
          <% :voted -> %>
              Your vote has been counted!
              <br/>
              <i class="fas fa-vote-yea vote-counted"></i>
          <% :new_question -> %>
            <PollinatrWeb.Components.QuestionComponent.ask question={@question} />
            <% _ -> %>
              <%= "Unknown state: #{@voter_state}" %>
          <% end %>
        <% :postshow -> %>
            We hope you enjoyed the show!
       <% _ ->  %>
        <%= "Unknown show state #{inspect(@show_mode)}" %>
      <% end %>

    """
  end
end
