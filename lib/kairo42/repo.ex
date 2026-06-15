defmodule Kairo42.Repo do
  use Ecto.Repo,
    otp_app: :kairo42,
    adapter: Ecto.Adapters.Postgres
end
