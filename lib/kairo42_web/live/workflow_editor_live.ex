defmodule Kairo42Web.WorkflowEditorLive do
  use Kairo42Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {[result], _} =
      Lua.eval!("""
      function add(a, b)
        function nested(a, b)
          return a * b
        end
        return nested(a, b)
      end

      return add(6, 3)
      """)

    {:ok, assign(socket, result: result)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex h-full w-full items-center justify-center">
        <div class="flex h-1/2 w-1/2 flex-col items-center justify-center rounded-lg bg-gray-100 p-4 shadow-lg">
          <h1 class="mb-4 text-2xl font-bold text-gray-800">Workflow Editor</h1>
          <p class="text-gray-600">This is where you can create and edit your workflows.</p>
          <p class="mt-4 text-gray-600">
            Lua Result: <span class="font-mono text-blue-500">{@result}</span>
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
