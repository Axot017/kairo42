defmodule Kairo42Web.WorkflowEditorLive do
  use Kairo42Web, :live_view

  alias Kairo42.Command.Workflow.Actor
  alias Kairo42.Command.Workflow.Command

  @default_lua_code """
  return "Hello from Lua"
  """

  @impl true
  def mount(_params, _session, socket) do
    form =
      %{"name" => "Test workflow", "lua_code" => @default_lua_code}
      |> to_form(as: :workflow)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:workflow_pid, nil)
     |> assign(:workflow_id, nil)
     |> assign(:status, "No workflow created yet.")
     |> assign(:result, nil)}
  end

  @impl true
  def handle_event("validate", %{"workflow" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :workflow))}
  end

  @impl true
  def handle_event("submit_workflow", %{"action" => "create", "workflow" => params}, socket) do
    cmd = %Command.Create{
      name: Map.get(params, "name", ""),
      lua_code: Map.get(params, "lua_code", "")
    }

    case Actor.create(cmd) do
      {:ok, {pid, workflow}} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: :workflow))
         |> assign(:workflow_pid, pid)
         |> assign(:workflow_id, workflow.id)
         |> assign(:status, "Created workflow #{workflow.id}")
         |> assign(:result, nil)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:form, to_form(params, as: :workflow))
         |> assign(:status, "Create failed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("submit_workflow", %{"action" => "trigger", "workflow" => params}, socket) do
    socket = assign(socket, :form, to_form(params, as: :workflow))

    case socket.assigns.workflow_pid do
      nil ->
        {:noreply, assign(socket, :status, "Create a workflow first.")}

      pid ->
        case Actor.trigger(pid) do
          {:ok, values} ->
            {:noreply,
             socket
             |> assign(:status, "Triggered workflow #{socket.assigns.workflow_id}")
             |> assign(:result, inspect(values))}

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:status, "Trigger failed: #{inspect(reason)}")
             |> assign(:result, nil)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto flex min-h-[calc(100vh-8rem)] w-full max-w-4xl items-center px-6 py-10">
        <div class="w-full rounded-3xl border border-slate-200 bg-white p-6 shadow-xl shadow-slate-200/70">
          <div class="mb-6">
            <p class="text-sm font-semibold uppercase tracking-[0.2em] text-indigo-500">Test page</p>
            <h1 class="mt-2 text-3xl font-bold tracking-tight text-slate-950">Workflow Editor</h1>
            <p class="mt-2 text-sm text-slate-600">
              Create a temporary workflow actor, then trigger its stored Lua code.
            </p>
          </div>

          <.form
            for={@form}
            id="workflow-editor-form"
            phx-change="validate"
            phx-submit="submit_workflow"
            class="space-y-5"
          >
            <.input
              field={@form[:name]}
              id="workflow-name-input"
              type="text"
              label="Name"
              class="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 shadow-sm transition focus:border-indigo-500 focus:outline-none focus:ring-4 focus:ring-indigo-100"
            />

            <.input
              field={@form[:lua_code]}
              id="workflow-lua-code-input"
              type="textarea"
              label="Lua code"
              rows="14"
              class="min-h-80 w-full rounded-xl border border-slate-300 bg-slate-950 px-4 py-3 font-mono text-sm leading-6 text-slate-100 shadow-inner transition placeholder:text-slate-500 focus:border-indigo-400 focus:outline-none focus:ring-4 focus:ring-indigo-100"
            />

            <div class="flex flex-wrap items-center gap-3">
              <button
                id="create-test-workflow-button"
                type="submit"
                name="action"
                value="create"
                class="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-indigo-200 transition hover:-translate-y-0.5 hover:bg-indigo-500 focus:outline-none focus:ring-4 focus:ring-indigo-100"
              >
                Create test workflow
              </button>

              <button
                id="trigger-test-workflow-button"
                type="submit"
                name="action"
                value="trigger"
                class="rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-800 shadow-sm transition hover:-translate-y-0.5 hover:border-indigo-300 hover:text-indigo-700 focus:outline-none focus:ring-4 focus:ring-indigo-100"
              >
                Trigger workflow
              </button>
            </div>
          </.form>

          <div id="workflow-status" class="mt-6 rounded-2xl bg-slate-50 p-4 text-sm text-slate-700">
            <p><span class="font-semibold text-slate-950">Status:</span> {@status}</p>
            <p :if={@workflow_id} class="mt-1">
              <span class="font-semibold text-slate-950">Workflow ID:</span> {@workflow_id}
            </p>
            <p :if={@result} class="mt-1">
              <span class="font-semibold text-slate-950">Lua result:</span>
              <code class="rounded bg-slate-900 px-2 py-1 text-slate-100">{@result}</code>
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
