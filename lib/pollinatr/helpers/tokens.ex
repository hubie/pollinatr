defmodule Pollinatr.Helpers.Tokens do
  @default_ttl 1 * 60 * 60 # 1 hour

  def encrypt(context, data) do
    Plug.Crypto.encrypt(secret(), to_string(context), data)
  end

  def decrypt(context, ciphertext, max_age \\ @default_ttl) when is_binary(ciphertext) do
    IO.inspect(Plug.Crypto.decrypt(secret(), to_string(context), ciphertext, max_age: max_age))
    Plug.Crypto.decrypt(secret(), to_string(context), ciphertext, max_age: max_age)
  end

  defp secret, do: PollinatrWeb.Endpoint.config(:secret_key_base)
end

