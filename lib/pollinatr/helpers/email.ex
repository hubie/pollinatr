defmodule Pollinatr.Helpers.Email do
  alias PollinatrWeb.Router.Helpers, as: Routes
  # import Swoosh.Email
  use Phoenix.Swoosh, view: PollinatrWeb.EmailView, layout: {PollinatrWeb.LayoutView, :email}

  def login_email(%{to: to, redirect_to: redirect_to} = args) do
    template_params = %{
      title: "Login Link",
      tenant_name: "The Slackies",
      watch_login_link: generateLoginLink(%{redirect_to: Routes.watch_path(PollinatrWeb.Endpoint, :index), email_address: to}),
      vote_login_link: generateLoginLink(%{redirect_to: Routes.vote_path(PollinatrWeb.Endpoint, :index), email_address: to})
    }

    IO.inspect(template_params)
    new()
    |> to(to)
    |> from(Application.fetch_env!(:pollinatr, Pollinatr.Helpers.Email)[:from_address])
    |> subject("Slackies Login Link")
    |> render_body("magic_token_login.html", template_params)
  end

  defp generateLoginLink(payload) do
    PollinatrWeb.Endpoint.url()
      <> Routes.redeem_path(PollinatrWeb.Endpoint, :index)
      <> "?"
      <> "token=" <> Pollinatr.Helpers.Tokens.encrypt(:magic_token, payload)
  end
end