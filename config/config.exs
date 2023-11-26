# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pollinatr,
  ecto_repos: [Pollinatr.Repo]

# Configures the endpoint
config :pollinatr, PollinatrWeb.Endpoint,
  render_errors: [view: PollinatrWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Pollinatr.PubSub,
  default_embedded_vote_mode: :vote,
  # 90 days
  unsubscribe_link_lifespan: 90 * 24 * 60 * 60

if Config.config_env() == :production do
  config :pollinatr, PollinatrWeb.Endpoint,
    cache_static_manifest: "priv/static/cache_manifest.json"
end

# config :goth, json: System.get_env("GOOGLE_SERVICE_KEY")

# config :elixir_google_spreadsheets, :client, request_workers: 20

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
# config :pollinatr, Pollinatr.Helpers.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, Swoosh.ApiClient.Hackney

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.19.7",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --external:/js/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.0.24",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
