defmodule Pollinatr.Chat.Message do
  @enforce_keys [:user_id, :session_id, :message]
  defstruct [:user_id, :nickname, :session_id, :message, :timestamp, :index]
end
