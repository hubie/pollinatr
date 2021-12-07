defmodule Pollinatr.Presence do
  use Phoenix.Presence,
    otp_app: :pollinatr,
    pubsub_server: Pollinatr.PubSub
end
