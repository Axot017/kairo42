defmodule Kairo42.Command.Workflow.RepositoryBehaviour do
  @moduledoc """
  Behaviour for the workflow repository, defining the required functions for interacting with workflow actors and events.
  """

  alias Kairo42.Command.Workflow.Actor
  alias Kairo42.Command.Workflow.Event

  @callback get_by_id(String.t()) :: {:ok, Actor.t() | nil} | {:error, term()}
  @callback persist_actor(Actor.t(), [Event.t()]) :: :ok | {:error, term()}
end
