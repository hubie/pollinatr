defmodule PollinatrWeb.ChatController do
  use PollinatrWeb, :controller

  def index(conn, params) do
    render(conn, "chat.html")
  end
end
