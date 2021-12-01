defmodule PollinatrWeb.Router do
  use PollinatrWeb, :router
  import PollinatrWeb.Plug.Session, only: [redirect_unauthorized: 2, validate_session: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PollinatrWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_session
    plug CORSPlug, origin: System.get_env("ALLOWED_ORIGINS", "localhost,127.0.0.1") |> String.split(",")
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :voter do
    plug :redirect_unauthorized, resource: :voter
  end

  pipeline :admin do
    plug :redirect_unauthorized, resource: :admin
  end


  scope "/", PollinatrWeb do
    pipe_through :browser

    live "/admin", Login.AccessCodeLive, :index

    live "/login", Login.MagicTokenLive, :index, as: :login

    live "/magical-redeemer", Login.TokenRedeemer, :index, as: :redeem

    live("/results", Results)
    live("/results/:view", Results)
  end

  scope "/", PollinatrWeb do
    pipe_through [:browser, :admin]
    live("/host", Host)
  end

  scope "/", PollinatrWeb do
    pipe_through [:browser, :voter]

    # live "/", VoterLive, :index
    live "/vote", VoterLive, :index
  end

  scope "/", PollinatrWeb do
    pipe_through [:browser, :voter]

    get "/", WatchController, :index
    get "/watch", WatchController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PollinatrWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PollinatrWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
