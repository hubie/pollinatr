defmodule Pollinatr.Helpers.Email do
  alias PollinatrWeb.Router.Helpers, as: Routes
  use Phoenix.Swoosh, view: PollinatrWeb.EmailView, layout: {PollinatrWeb.LayoutView, :email}

  def login_email(%{to: to, redirect_to: redirect_to, nickname: nickname} = _args) do
    template_params = %{
      title: "Login Link",
      tenant_name: "The Slackies",
      watch_login_link:
        generateLoginLink(%{
          redirect_to: Routes.watch_path(PollinatrWeb.Endpoint, :index),
          email_address: to,
          nickname: nickname
        }),
      vote_login_link:
        generateLoginLink(%{
          redirect_to: Routes.chat_path(PollinatrWeb.Endpoint, :index),
          email_address: to,
          nickname: nickname
        }),
      unsubscribe_link: generateUnsubscribeLink(%{email_address: to, list_name: "login"})
    }

    new()
    |> to(to)
    |> from(Application.fetch_env!(:pollinatr, Pollinatr.Helpers.Email)[:from_address])
    |> subject("Slackies Login Link")
    |> render_body("magic_token_login.html", template_params)
    |> put_provider_option(:configuration_set_name, "magic_login_link")
  end

  defp generateLoginLink(payload) do
    getBaseUrl() <>
      Routes.redeem_path(PollinatrWeb.Endpoint, :index) <>
      "?" <>
      "token=" <> Pollinatr.Helpers.Tokens.encrypt(:magic_token, payload)
  end

  defp generateUnsubscribeLink(payload) do
    getBaseUrl() <>
      Routes.unsubscribe_path(PollinatrWeb.Endpoint, :index) <>
      "?" <>
      "token=" <> Pollinatr.Helpers.Tokens.encrypt(:magic_token, payload)
  end

  defp getBaseUrl() do
    Application.fetch_env!(:pollinatr, PollinatrWeb.Endpoint)[:url][:scheme] <>
      "://" <>
      Application.fetch_env!(:pollinatr, PollinatrWeb.Endpoint)[:url][:host]
  end
end
