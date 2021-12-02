defmodule Pollinatr.Login.Form do
  alias Pollinatr.User

  def get_user_by_code(validation_code) do
    User.get_user(%{validation_code: validation_code})
  end
end
