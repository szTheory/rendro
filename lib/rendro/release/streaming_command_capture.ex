defmodule Rendro.Release.StreamingCommandCapture do
  @moduledoc false

  defstruct output: ""
end

defimpl Collectable, for: Rendro.Release.StreamingCommandCapture do
  def into(%Rendro.Release.StreamingCommandCapture{} = capture) do
    collector = fn
      %Rendro.Release.StreamingCommandCapture{} = capture, {:cont, chunk} ->
        IO.write(chunk)
        %{capture | output: capture.output <> chunk}

      %Rendro.Release.StreamingCommandCapture{} = capture, :done ->
        capture.output

      _capture, :halt ->
        :ok
    end

    {capture, collector}
  end
end
