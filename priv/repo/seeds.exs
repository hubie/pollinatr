# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Pollinatr.Repo.insert!(%Pollinatr.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Pollinatr.Repo.insert!(%Pollinatr.Schema.Tenants{name: "The 2022 Slackies"})
