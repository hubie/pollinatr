# lib/my_app_web/views/error_view.ex
defmodule PollinatrWeb.ErrorForbidden do
  use PollinatrWeb, :view

  def render("403.html", _assigns) do
    "Forbidden"
  end
end
