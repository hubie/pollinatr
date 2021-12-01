defmodule Pollinatr.Helpers.Email do
  # import Swoosh.Email
  use Phoenix.Swoosh, view: PollinatrWeb.EmailView, layout: {PollinatrWeb.LayoutView, :email}

  def login_email(%{to: to, redirect_to: redirect_to} = args) do
    IO.inspect(args)
    template_params = %{
      title: "Login Link",
      tenant_name: "The Slackies",
      login_link: generateLoginLink(%{redirect_to: redirect_to, email_address: to})
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
      <> PollinatrWeb.Router.Helpers.redeem_path(PollinatrWeb.Endpoint, :index)
      <> "?"
      <> "token=" <> Pollinatr.Helpers.Tokens.encrypt(:magic_token, payload)
  end
end