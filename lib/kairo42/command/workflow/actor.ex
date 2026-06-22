defmodule Kairo42.Command.Workflow.Actor do
  @moduledoc """
  Represents an actor in a workflow command.
  """

  alias Kairo42.Command.Workflow.Event
  alias Kairo42.Command.Workflow.Command

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t() | nil,
          lua_code: String.t() | nil,
          created_at: DateTime.t() | nil
        }

  defstruct [:id, :name, :lua_code, :created_at]

  use Kairo42.Command.Common.Actor,
    registry: Kairo42.Command.Workflow.Registry,
    supervisor: Kairo42.Command.Workflow.Supervisor,
    create_cmd: Kairo42.Command.Workflow.Command.Create,
    # 15 minutes in milliseconds
    timeout: 15 * 60 * 1000

  @repository Application.compile_env(
                :kairo42,
                [__MODULE__, :repository]
              )

  def load_aggregate(id) do
    @repository.get_by_id(id)
  end

  def create_aggregate(id, %Command.Create{} = cmd) when is_binary(id) do
    created = %Event.Created{
      aggregate_id: id,
      name: cmd.name,
      lua_code: cmd.lua_code,
      created_at: DateTime.utc_now(),
      sequence_number: 1
    }

    new_profile =
      %__MODULE__{id: id}
      |> handle(created)

    with :ok <- @repository.persist_actor(new_profile, [created]) do
      {:ok, new_profile}
    end
  end

  def trigger(pid) when is_pid(pid) do
    GenServer.call(pid, :trigger)
  end

  def handle_call(:trigger, _from, %__MODULE__{lua_code: lua_code} = state)
      when is_binary(lua_code) do
    lua_code
    |> run_lua()
    |> reply(state)
  end

  def handle_call(:trigger, _from, state) do
    reply({:error, :no_lua_code}, state)
  end

  defp run_lua(lua_code) do
    case Lua.eval!(lua_code) do
      {values, _lua_state} -> {:ok, values}
    end
  rescue
    exception -> {:error, Exception.message(exception)}
  catch
    kind, reason -> {:error, {kind, reason}}
  end

  defp handle(%__MODULE__{} = actor, %Event.Created{} = event) do
    %__MODULE__{
      actor
      | name: event.name,
        lua_code: event.lua_code,
        created_at: event.created_at
    }
  end
end
