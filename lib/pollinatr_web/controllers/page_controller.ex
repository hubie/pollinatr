defmodule PollinatrWeb.PageController do
  use PollinatrWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
