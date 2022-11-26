defmodule PollinatrWeb.Plug.Tenant do
  import Plug.Conn
  alias Pollinatr.Schema.Tenants

  def init([:use_default] = _default) do
    %{id: tenant_id} = Tenants |> Ecto.Query.first |> Pollinatr.Repo.one!(skip_tenant_id: true)
    IO.inspect(Tenants |> Ecto.Query.first |> Pollinatr.Repo.one!(skip_tenant_id: true), label: "tenant")
    tenant_id
  end
  def init(args) do
    IO.inspect("Unable to determine tenant_id")
    # lookup tenant
    args
  end


  def call(conn, default_tenant_id) do
    IO.inspect("should_call")
    case get_session(conn, :tenant_id) do
      nil ->
        IO.inspect(default_tenant_id, label: "setting default_tenant_id")
        Pollinatr.Repo.put_tenant_id(default_tenant_id)
        conn
        |> put_session(:tenant_id, default_tenant_id)

      tenant_id ->
        # TODO: Should validate the tenant_id
        Pollinatr.Repo.put_tenant_id(tenant_id)
        conn
    end
  end
end
