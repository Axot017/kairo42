defmodule Kairo42.Application do
  @moduledoc """
  The Kairo42 Application Service.
  """

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      Kairo42Web.Telemetry,
      Kairo42.Repo,
      {Cluster.Supervisor, [topologies, [name: App73.ClusterSupervisor]]},
      {Phoenix.PubSub, name: Kairo42.PubSub},
      Kairo42Web.Endpoint,
      {Horde.Registry, keys: :unique, name: Kairo42.Command.Workflow.Registry},
      {Horde.DynamicSupervisor, name: Kairo42.Command.Workflow.Supervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: Kairo42.Supervisor]

    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    Kairo42Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
