defmodule Pollinatr.Chat.Message do
  @enforce_keys [:user_id, :username, :session_id, :message]
  defstruct [:user_id, :username, :nickname, :session_id, :message, :timestamp, :index]
end
