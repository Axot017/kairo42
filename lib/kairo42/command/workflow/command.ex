defmodule Kairo42.Command.Workflow.Command do
  @moduledoc """
  Represents a command in a workflow.
  """

  @type t :: Command.Create.t()

  defmodule Create do
    @moduledoc """
    Represents a 'Create' command in a workflow.
    """

    @type t :: %__MODULE__{
            name: String.t(),
            lua_code: String.t()
          }

    defstruct [
      :name,
      :lua_code
    ]
  end
end
