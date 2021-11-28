defmodule PollinatrWeb.Live.Helper do
  def signing_salt do
    PollinatrWeb.Endpoint.config(:live_view)[:signing_salt]
  end
end
