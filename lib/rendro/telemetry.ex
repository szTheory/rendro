defmodule Rendro.Telemetry do
  @moduledoc """
  Telemetry event definitions and helpers for the Rendro render pipeline.

  ## Event Naming

  All events follow the pattern `[:rendro, :pipeline, :stage_name]` with
  `:telemetry.span/3` providing automatic `start`, `stop`, and `exception`
  suffixes. A top-level `[:rendro, :render]` span wraps the full pipeline.

  ## Metadata

  Start events include:

      %{render_id: String.t(), stage: atom(), document_type: atom(), deterministic: boolean()}

  Stop events add:

      %{duration: integer(), status: :ok | :error, page_count: non_neg_integer(), byte_size: non_neg_integer()}

  Exception events add:

      %{kind: atom(), reason: term(), stacktrace: list()}
  """

  @stage_names [:build, :compose, :measure, :paginate, :render]

  @event_prefixes Enum.map(@stage_names, &[:rendro, :pipeline, &1])

  @render_prefix [:rendro, :render]

  @spec event_prefixes() :: [list(atom())]
  def event_prefixes, do: @event_prefixes

  @spec render_prefix() :: list(atom())
  def render_prefix, do: @render_prefix

  @spec stage_names() :: [atom()]
  def stage_names, do: @stage_names

  @spec all_event_names() :: [list(atom())]
  def all_event_names do
    for prefix <- [@render_prefix | @event_prefixes],
        suffix <- [:start, :stop, :exception] do
      prefix ++ [suffix]
    end
  end

  @spec generate_render_id() :: String.t()
  def generate_render_id do
    <<a::48, _::4, b::12, _::2, c::62>> = :crypto.strong_rand_bytes(16)
    encode_uuid(<<a::48, 4::4, b::12, 2::2, c::62>>)
  end

  defp encode_uuid(<<a::32, b::16, c::16, d::16, e::48>>) do
    hex = fn int, len ->
      int |> Integer.to_string(16) |> String.downcase() |> String.pad_leading(len, "0")
    end

    "#{hex.(a, 8)}-#{hex.(b, 4)}-#{hex.(c, 4)}-#{hex.(d, 4)}-#{hex.(e, 12)}"
  end
end
