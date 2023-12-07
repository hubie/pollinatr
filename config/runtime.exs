import Config
import Dotenvy

source(["#{config_env()}.env", "#{config_env()}.override.env", System.get_env()])

config :pollinatr,
  admin_login_code: env!("ADMIN_LOGIN_CODE", :string, "abcd")

config :swoosh, :api_client, Swoosh.ApiClient.Hackney

config :pollinatr, Pollinatr.Helpers.Email,
  from_address: env!("EMAIL_FROM", :string, "noreply@example.com")

config :pollinatr, Pollinatr.Helpers.Mailer,
  adapter: Swoosh.Adapters.AmazonSES,
  region: env!("AWS_SES_REGION", :string),
  access_key: env!("AWS_SES_ACCESS_KEY", :string),
  secret: env!("AWS_SES_SECRET_KEY", :string)

config :pollinatr, PollinatrWeb.Endpoint,
  live_view: [signing_salt: env!("LIVEVIEW_SIGNING_SALT", :string!)],
  default_video_provider: env!("DEFAULT_VIDEO_PROVIDER", :string, "streamshark"),
  ant_media_stream_url: env!("ANT_MEDIA_STREAM_URL", :string, ""),
  aws_ivs_stream_url: env!("AWS_IVS_STREAM_URL", :string, ""),
  streamshark_stream_url: env!("STREAMSHARK_STREAM_URL", :string, "")

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug,
  handle_sasl_reports: true

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  # database_url =
  #   System.get_env("DATABASE_URL") ||
  #     raise """
  #     environment variable DATABASE_URL is missing.
  #     For example: ecto://USER:PASS@HOST/DATABASE
  #     """

  config :logger, level: :info

  # config :pollinatr, Pollinatr.Repo,
  #   # ssl: true,
  #   # socket_options: [:inet6],
  #   url: database_url,
  #   pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    env!("SECRET_KEY_BASE", :string) ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = env!("PHX_HOST", :string, "pollinatr.fly.dev")

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint (by setting server: true)
  #
  config :pollinatr, PollinatrWeb.Endpoint,
    url: [host: host, scheme: "https", port: 443],
    server: true,
    # url: [host: "pollinatr.fly.dev", port: 80],
    check_origin:
      env!("CHECK_ORIGINS", :string!, "//localhost,//pollinatr.fly.dev") |> String.split(","),
    secret_key_base: secret_key_base,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: env!("PORT", :integer, 4000)
    ]

  maybe_ipv6 = if env!("ECTO_IPV6"), do: [:inet6], else: []

  config :pollinatr, Pollinatr.Repo,
    adapter: Ecto.Adapters.Postgres,
    url: env!("DATABASE_URL"),
    pool_size: env!("DB_POOL_SIZE", :integer, 9),
    socket_options: maybe_ipv6

  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :pollinatr, Pollinatr.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
