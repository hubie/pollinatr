defmodule PollinatrWeb.Plug.Tenant do
  import Plug.Conn
  alias Pollinatr.Schema.Tenants
  alias Pollinatr.Repo

  def init(args) do
    args
  end


  def call(conn, %{use_default: use_default}) do
    IO.inspect("should_call")
    case get_session(conn, :tenant_id) do
      nil ->
        if( use_default == true) do
          tenant_id = get_default_tenant_id()
          IO.inspect(tenant_id, label: "setting default_tenant_id")
          Repo.put_tenant_id(tenant_id)
          conn
          |> put_session(:tenant_id, tenant_id)
        end
      tenant_id ->
        # TODO: Should validate the tenant_id
        Repo.put_tenant_id(tenant_id)
        conn
    end
  end

  defp get_default_tenant_id do
    %{id: tenant_id} = Tenants |> Ecto.Query.first |> Repo.one!(skip_tenant_id: true)
    tenant_id
  end
end
