defmodule Pollinatr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Pollinatr.Repo,
      # Start the Telemetry supervisor
      PollinatrWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Pollinatr.PubSub},
      # Start the Endpoint (http/https)
      PollinatrWeb.Endpoint,
      # Start a worker by calling: Pollinatr.Worker.start_link(arg)
      # {Pollinatr.Worker, arg}
      Pollinatr.Presence,
      {Pollinatr.ResultsSupervisor, [name: Pollinatr.ResultsSupervisor]},
      {Pollinatr.Chat.Supervisor, [name: Pollinatr.Chat.Supervisor]},
      {Pollinatr.Questions, [name: Pollinatr.Questions]},

    ]

    :ets.new(:auth_table, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(:auth_codes, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(:auth_meta, [:set, :public, :named_table, read_concurrency: true])
    :ets.new(:users, [:set, :public, :named_table, read_concurrency: true])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pollinatr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PollinatrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
