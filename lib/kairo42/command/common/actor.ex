defmodule Kairo42.Command.Common.Actor do
  @moduledoc """
  A utility module for creating actors in a distributed system using Horde.
  """

  @callback load_aggregate(id :: term()) :: {:ok, aggregate :: term()} | {:error, error :: any()}

  @callback create_aggregate(
              id :: term(),
              command :: term()
            ) :: {:ok, aggregate :: term()} | {:error, error :: any()}

  defmacro __using__(opts) do
    registry = Keyword.get(opts, :registry)
    supervisor = Keyword.get(opts, :supervisor)
    create_cmd = Keyword.get(opts, :create_cmd)
    timeout = Keyword.get(opts, :timeout)

    quote do
      require Logger
      use GenServer, restart: :transient

      @behaviour Kairo42.Command.Common.Actor

      unquote(timeout_functions(timeout))
      unquote(start_link_function(registry))
      unquote(init_functions(supervisor))
      unquote(load_functions())
      unquote(create_function(create_cmd))
      unquote(state_function())
    end
  end

  defp state_function() do
    quote do
      def state(pid) do
        GenServer.call(pid, :state)
      end

      def handle_call(:state, _from, state) do
        case state.created_at do
          nil -> nil
          _ -> state
        end
        |> reply(state)
      end
    end
  end

  defp create_function(create_cmd) when not is_nil(create_cmd) do
    quote do
      def create(%unquote(create_cmd){} = cmd) do
        case new() do
          {:ok, {pid, id}} ->
            Logger.debug("Creating new #{__MODULE__} aggregate", id: id)
            GenServer.call(pid, {:create, cmd})

          {:error, reason} ->
            Logger.error("Failed to start #{__MODULE__} actor", reason: reason)
            {:error, reason}
        end
      end

      def handle_call({:create, %unquote(create_cmd){} = cmd}, _from, state) do
        case create_aggregate(state.id, cmd) do
          {:ok, aggregate} ->
            Logger.debug("Created #{__MODULE__} aggregate", id: state.id)
            reply({:ok, {self(), aggregate}}, aggregate)

          {:error, reason} ->
            Logger.error("Failed to create #{__MODULE__} aggregate: #{inspect(reason)}",
              id: state.id,
              reason: reason
            )

            stop({:error, reason}, state)
        end
      end
    end
  end

  defp create_function(_) do
    quote do
    end
  end

  defp start_link_function(registry) when not is_nil(registry) do
    quote do
      def start_link(id) do
        GenServer.start_link(
          __MODULE__,
          id,
          name: {:via, Horde.Registry, {unquote(registry), id}}
        )
      end
    end
  end

  defp start_link_function(_) do
    quote do
    end
  end

  def load_functions() do
    quote do
      def init(args) do
        GenServer.cast(self(), {:load, args})
        {:ok, %__MODULE__{}}
      end

      def handle_cast({:load, %{id: id, expected_state: :new}}, state) when is_binary(id) do
        Logger.debug("Initializing new #{__MODULE__}", id: id)

        noreply(%__MODULE__{id: id})
      end

      def handle_cast({:load, %{id: id}}, state) when is_binary(id) do
        case load_aggregate(id) do
          {:ok, nil} ->
            Logger.debug("No #{__MODULE__} found, initializing new #{__MODULE__}", id: id)

            noreply(%__MODULE__{id: id})

          {:ok, profile} ->
            Logger.debug("Loaded #{__MODULE__}", id: id)

            noreply({:ok, profile})

          {:error, reason} ->
            Logger.error("Failed to load #{__MODULE__}", id: id, reason: reason)

            {:stop, :shutdown, state}
        end
      end
    end
  end

  def init_functions(supervisor) when not is_nil(supervisor) do
    quote do
      defp get_internal(%{id: id, expected_state: expected_state} = args) when is_binary(id) do
        case {Horde.DynamicSupervisor.start_child(
                unquote(supervisor),
                {__MODULE__, args}
              ), expected_state} do
          {{:ok, pid}, _} ->
            Logger.debug("Started #{__MODULE__} actor with ID: #{id}")
            {:ok, {pid, id}}

          {{:error, {:already_started, pid}}, :exist} ->
            Logger.debug("#{__MODULE__} actor with ID: #{id} already started")
            {:ok, {pid, id}}

          {{:error, {:already_started, pid}}, :new} ->
            Logger.error("#{__MODULE__} with ID: #{id} should not exist")
            {:error, :actor_already_exist}

          {:error, reason} ->
            Logger.error(
              "Failed to start #{__MODULE__} actor with ID: #{id}, reason: #{inspect(reason)}"
            )

            {:error, reason}
        end
      end

      def get(id) when is_binary(id) do
        get_internal(%{id: id, expected_state: :exist})
      end

      def new() do
        id = Ecto.ULID.generate()
        get_internal(%{expected_state: :new, id: id})
      end
    end
  end

  def getter_function(_) do
    quote do
    end
  end

  defp timeout_functions(timeout) when is_integer(timeout) do
    quote do
      defp stop(answer, state) do
        {:stop, :normal, answer, state}
      end

      def handle_info(:timeout, %{id: id}) do
        Logger.debug("#{__MODULE__} actor timed out", id: id)

        {:stop, :normal, state}
      end

      defp reply(answer, state) do
        {:reply, answer, state, unquote(timeout)}
      end

      defp noreply(state) do
        {:noreply, state, unquote(timeout)}
      end
    end
  end

  defp timeout_functions(_) do
    quote do
      defp stop(answer, state) do
        {:stop, :normal, answer, state}
      end

      defp reply(answer, state) do
        {:reply, answer, state}
      end

      defp noreply(state) do
        {:noreply, state}
      end
    end
  end
end
