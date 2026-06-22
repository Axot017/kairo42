defmodule Kairo42.Command.Workflow.Repository do
  @moduledoc """
  Repository module for managing workflow actors and events.
  """

  alias Kairo42.Command.Workflow.Actor
  require Logger

  def get_by_id("missing") do
    {:ok, nil}
  end

  def get_by_id("error") do
    {:error, :not_found}
  end

  def get_by_id(id) when is_binary(id) do
    Logger.debug("Fetching actor by ID: #{id}")

    {:ok,
     %Actor{id: id, name: "Mock Actor", lua_code: "return 'mock'", created_at: DateTime.utc_now()}}
  end

  def persist_actor(%Actor{name: "error"}, _) do
    {:error, :persist_failed}
  end

  def persist_actor(%Actor{} = actor, _) do
    Logger.debug("Persisting actor: #{inspect(actor)}")
    :ok
  end
end
