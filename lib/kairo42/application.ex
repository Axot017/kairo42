defmodule Kairo42.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Kairo42Web.Telemetry,
      Kairo42.Repo,
      {DNSCluster, query: Application.get_env(:kairo42, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Kairo42.PubSub},
      # Start a worker by calling: Kairo42.Worker.start_link(arg)
      # {Kairo42.Worker, arg},
      # Start to serve requests, typically the last entry
      Kairo42Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kairo42.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Kairo42Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
