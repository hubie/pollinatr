defmodule Pollinatr.Chat.Message do
  @enforce_keys [:tenant_id, :user_id, :username, :session_id, :message]
  defstruct [:tenant_id, :user_id, :username, :nickname, :session_id, :message, :timestamp, :index]
end
