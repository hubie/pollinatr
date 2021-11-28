defmodule Pollinatr.Login.Form do
  alias Pollinatr.User

  def get_user_by_code(user) do
    user
    |> User.get_user()
  end
end
