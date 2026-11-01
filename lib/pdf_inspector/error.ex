defmodule PdfInspector.Error do
  @moduledoc "An error returned by the native PDF parser."
  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}
end
