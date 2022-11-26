defmodule Pollinatr.Repo do
  use Ecto.Repo,
    otp_app: :pollinatr,
    adapter: Ecto.Adapters.Postgres
  require Ecto.Query

  @tenant_key {__MODULE__, :tenant_id}

  @impl true
  def prepare_query(_operation, query, opts) do
    IO.inspect(opts, label: "OPTS!")
    cond do
      opts[:skip_tenant_id] || opts[:schema_migration] ->
        {query, opts}

      tenant_id = opts[:tenant_id] ->
        {Ecto.Query.where(query, tenant_id: ^tenant_id), opts}

      true ->
        raise "expected :tenant_id or :skip_tenant_id to be set"
    end
  end

  def put_tenant_id(tenant_id) do
    IO.inspect(tenant_id, label: "setting tenant_id")
    Process.put(@tenant_key, tenant_id)
  end

  def get_tenant_id() do
    Process.get(@tenant_key)
  end

  @impl true
  def default_options(_operation) do
    IO.inspect(get_tenant_id(), label: "getting default_options")
    [tenant_id: get_tenant_id()]
  end
end
