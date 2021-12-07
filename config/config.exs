# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pollinatr,
  ecto_repos: [Pollinatr.Repo]

config :pollinatr, Pollinatr.Repo,
  database: "pollinatr",
  username: "pollinatr",
  password: "password",
  hostname: "127.0.0.1",
  port: "15432"

# Configures the endpoint
config :pollinatr, PollinatrWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PollinatrWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Pollinatr.PubSub,
  live_view: [signing_salt: System.get_env("LIVEVIEW_SIGNING_SALT")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  default_embedded_vote_mode: :vote,
  default_video_provider: System.get_env("DEFAULT_VIDEO_PROVIDER", "streamshark"),
  streamshark_stream_url: System.get_env("STREAMSHARK_STREAM_URL"),
  aws_ivs_stream_url: System.get_env("AWS_IVS_STREAM_URL"),
  # 90 days
  unsubscribe_link_lifespan: 90 * 24 * 60 * 60

config :goth, json: System.get_env("GOOGLE_SERVICE_KEY")

config :elixir_google_spreadsheets, :client, request_workers: 20

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

config :pollinatr, Pollinatr.Helpers.Email, from_address: System.get_env("EMAIL_FROM")

config :pollinatr, Pollinatr.Helpers.Mailer,
  adapter: Swoosh.Adapters.AmazonSES,
  region: System.get_env("AWS_SES_REGION"),
  access_key: System.get_env("AWS_SES_ACCESS_KEY"),
  secret: System.get_env("AWS_SES_SECRET_KEY")

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
