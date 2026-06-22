defmodule Kairo42.Command.Workflow.Event do
  @moduledoc """
  Represents an event in a workflow command.
  """

  @type t :: Event.Created.t()

  defmodule Created do
    @moduledoc """
    Represents a 'Created' event in a workflow command.
    """

    @type t :: %__MODULE__{
            aggregate_id: String.t(),
            name: String.t(),
            lua_code: String.t(),
            created_at: DateTime.t(),
            sequence_number: non_neg_integer()
          }

    defstruct [
      :aggregate_id,
      :name,
      :lua_code,
      :created_at,
      :sequence_number
    ]
  end
end
