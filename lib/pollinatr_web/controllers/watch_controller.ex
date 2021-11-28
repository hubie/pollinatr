defmodule PollinatrWeb.WatchController do
  use PollinatrWeb, :controller

  def index(conn, params) do
    player = Map.get(params, "player", Application.get_env(:pollinatr, PollinatrWeb.Endpoint)[:default_video_player])
    render(conn, "watch.html", player: player)
  end
end