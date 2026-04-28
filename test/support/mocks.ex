defmodule Rendro.Test.Mocks do
  @moduledoc """
  Minimal in-test stand-ins for optional ecosystem libraries (`Threadline`,
  `Mailglass`) and any Swoosh helpers that aren't part of the test
  dependency graph.

  These modules are defined in the test environment only. They allow the
  optional adapters in `Rendro.Adapters.*` to compile and be exercised
  without pulling the real packages into `mix.exs`.

  ## Threadline

  Records calls to `record_action/2` in an ETS table keyed by the test
  process pid so tests can assert on what the adapter forwarded — even
  when telemetry handlers fire in a different process (e.g. inside a
  `Task.async` spawned by the render pipeline).

  ## Mailglass.Message

  Provides a minimal struct wrapping a `Swoosh.Email`, plus
  `update_swoosh/2` so the Mailglass attach path can be verified.
  """

  @table :rendro_threadline_calls

  @doc """
  Ensures the ETS table backing the Threadline stub exists.

  Called once from `test_helper.exs`.
  """
  def ensure_table! do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :bag])
        :ok

      _ ->
        :ok
    end
  end

  @doc """
  Returns the list of `record_action/2` calls captured for the current
  test process (and any process it spawned), in chronological order.
  """
  def threadline_calls do
    pid = test_pid()

    @table
    |> :ets.lookup(pid)
    |> Enum.map(fn {_pid, seq, action, metadata} -> {seq, action, metadata} end)
    |> Enum.sort_by(fn {seq, _action, _meta} -> seq end)
    |> Enum.map(fn {_seq, action, meta} -> {action, meta} end)
  end

  @doc "Clears recorded Threadline calls for the current test process."
  def reset_threadline do
    pid = test_pid()
    :ets.match_delete(@table, {pid, :_, :_, :_})
    :ok
  end

  @doc false
  def __record_call__(action, metadata) do
    pid = test_pid()
    seq = System.unique_integer([:monotonic, :positive])
    :ets.insert(@table, {pid, seq, action, metadata})
    :ok
  end

  # Resolve the "owning" test process for the current execution context.
  # When the render pipeline spawns a Task, the spawned process inherits the
  # `:"$callers"` ancestry chain set by Task. We walk it to find the test
  # process so cross-process telemetry handlers route their captures back
  # to the right test bucket.
  defp test_pid do
    case Process.get(:"$callers") do
      [pid | _] -> pid
      _ -> self()
    end
  end
end

# Stub Threadline module. Only defined if the real library is not loaded so we
# never shadow the real implementation during integration runs.
unless Code.ensure_loaded?(Threadline) do
  defmodule Threadline do
    @moduledoc false

    alias Rendro.Test.Mocks

    @doc """
    Stub for `Threadline.record_action/2`. Records the call into a shared
    ETS table keyed by the test process so cross-process telemetry handlers
    (e.g. those firing inside `Task.async`) are still observable from tests.
    """
    def record_action(action, metadata) do
      Mocks.__record_call__(action, metadata)
      :ok
    end
  end
end

unless Code.ensure_loaded?(Swoosh.Attachment) do
  defmodule Swoosh.Attachment do
    @moduledoc false
    defstruct [:filename, :content_type, :data, :type, :headers]

    def new(data, opts \\ []) do
      %__MODULE__{
        data: data,
        filename: Keyword.get(opts, :filename),
        content_type: Keyword.get(opts, :content_type),
        type: Keyword.get(opts, :type, :attachment),
        headers: Keyword.get(opts, :headers, [])
      }
    end
  end
end

unless Code.ensure_loaded?(Swoosh.Email) do
  defmodule Swoosh.Email do
    @moduledoc false
    defstruct subject: nil,
              from: nil,
              to: [],
              cc: [],
              bcc: [],
              reply_to: nil,
              text_body: nil,
              html_body: nil,
              attachments: [],
              headers: %{},
              private: %{},
              assigns: %{},
              provider_options: %{}

    def new(opts \\ []), do: struct!(__MODULE__, opts)

    def subject(%__MODULE__{} = email, subject), do: %{email | subject: subject}

    def from(%__MODULE__{} = email, from), do: %{email | from: normalize_address(from)}

    def to(%__MODULE__{} = email, to) do
      %{email | to: List.wrap(email.to) ++ [normalize_address(to)]}
    end

    def attachment(%__MODULE__{} = email, %Swoosh.Attachment{} = att) do
      %{email | attachments: email.attachments ++ [att]}
    end

    defp normalize_address({_name, _addr} = pair), do: pair
    defp normalize_address(addr) when is_binary(addr), do: {"", addr}
  end
end

unless Code.ensure_loaded?(Mailglass) do
  defmodule Mailglass.Message do
    @moduledoc false
    defstruct [:swoosh, :meta]

    @doc "Replace the wrapped Swoosh email in a Mailglass.Message."
    def update_swoosh(%__MODULE__{} = message, %Swoosh.Email{} = swoosh) do
      %{message | swoosh: swoosh}
    end
  end

  defmodule Mailglass do
    @moduledoc false
    @doc "Marker module to satisfy `Code.ensure_loaded?(Mailglass)` in adapters."
    def __mailglass_stub__, do: true
  end
end

unless Code.ensure_loaded?(Accrue) do
  defmodule Accrue.LineItem do
    @moduledoc false
    defstruct [:description, :quantity, :unit_amount, :subtotal]
  end
end

unless Code.ensure_loaded?(Accrue) do
  defmodule Accrue.Invoice do
    @moduledoc false
    defstruct [:id, :customer, :line_items, :total, :issued_at]
  end
end

unless Code.ensure_loaded?(Accrue) do
  defmodule Accrue do
    @moduledoc false
    @doc "Marker module to satisfy `Code.ensure_loaded?(Accrue)` in adapters."
    def __accrue_stub__, do: true
  end
end

defmodule Rendro.Test.Mocks.AdapterReloader do
  @moduledoc """
  Force-recompiles optional adapter modules so their `Code.ensure_loaded?/1`
  guards re-evaluate after stub modules above have been defined.

  In `lib/` the adapter files were compiled before the stubs existed, so
  the module bodies inside `if Code.ensure_loaded?(...) do ... end` were
  skipped. Calling `recompile/0` from `test_helper.exs` brings them online.
  """

  @adapter_files [
    "lib/rendro/adapters/threadline.ex",
    "lib/rendro/adapters/mailglass.ex",
    "lib/rendro/adapters/accrue.ex"
  ]

  def recompile do
    project_root = File.cwd!()

    for relative <- @adapter_files,
        path = Path.join(project_root, relative),
        File.exists?(path) do
      Code.compile_file(path)
    end

    :ok
  end
end
