defmodule PollinatrWeb.Components.ChatboxComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div>
      <%= for %{user_id: sender, message: message} <- @messages do %>
        <%= sender %>: <%= message %> <br/>
      <% end %>
    </div>
    """
  end
end
