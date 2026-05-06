defmodule Rendro.ProtectTest do
  use ExUnit.Case, async: true

  alias Rendro.Adapters.Qpdf
  alias Rendro.{Artifact, Protect}

  defmodule FakeAdapter do
    @behaviour Rendro.Protect.Adapter

    @impl true
    def protect(%Artifact{binary: binary}, opts) do
      send(self(), {:fake_adapter_called, opts})
      {:ok, binary <> "::protected"}
    end
  end

  defmodule FailingAdapter do
    @behaviour Rendro.Protect.Adapter

    @impl true
    def protect(_artifact, _opts), do: {:error, :adapter_down}
  end

  defp sample_artifact do
    %Artifact{
      binary: "%PDF-sample",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-sample"), case: :lower),
      diagnostics: [%{type: :info}],
      metadata: %{page_count: 1, deterministic: true}
    }
  end

  test "publishes only the truthful six advisory permissions" do
    assert Protect.supported_permissions() == [
             :annotate,
             :assemble,
             :copy,
             :fill_forms,
             :modify,
             :print
           ]
  end

  test "protects an artifact with minimal password-safe metadata and marks the result non-deterministic" do
    {:ok, protected} =
      Protect.password(sample_artifact(),
        adapter: FakeAdapter,
        open_password: "open-secret",
        owner_password: "owner-secret",
        advisory_permissions: [:copy, :print]
      )

    assert_receive {:fake_adapter_called, opts}
    assert opts.algorithm == :aes_256
    assert opts.advisory_permissions == [:copy, :print]
    assert protected.binary == "%PDF-sample::protected"
    assert protected.metadata.page_count == 1
    assert protected.metadata.deterministic == false

    assert protected.metadata.protection == %{
             algorithm: :aes_256,
             advisory_permissions: [:copy, :print],
             has_open_password: true,
             has_owner_password: true
           }

    refute Map.has_key?(protected.metadata.protection, :adapter)
    refute Map.has_key?(protected.metadata.protection, :deterministic)
    refute Map.has_key?(protected.metadata.protection, :protected)
    refute inspect(protected.metadata.protection) =~ "open-secret"
    refute inspect(protected.metadata.protection) =~ "owner-secret"
  end

  test "requires a non-empty open password" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: " ",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :open_password, :empty}
  end

  test "rejects malformed top-level protection options with a typed protect error" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(), %{open_password: "open-secret"})

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :options, %{open_password: "open-secret"}}
    refute_receive {:fake_adapter_called, _}
  end

  test "requires a non-empty owner password" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: "open-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:missing_required_option, :owner_password}
  end

  test "rejects invalid adapter values before adapter execution" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: "Rendro.Adapters.Qpdf",
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :adapter, "Rendro.Adapters.Qpdf"}
    refute_receive {:fake_adapter_called, _}
  end

  test "rejects modules that do not implement the protection adapter contract" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: Map,
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :adapter, Map}
    refute_receive {:fake_adapter_called, _}
  end

  test "rejects non-binary password values before adapter execution" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: :secret,
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :open_password, :secret}
    refute_receive {:fake_adapter_called, _}
  end

  test "rejects passwords with unsafe control characters before adapter execution" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: "open-secret\n--replace-input",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :open_password, :unsafe_characters}
    refute_receive {:fake_adapter_called, _}
  end

  test "rejects unsupported algorithms" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               algorithm: :aes_128,
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert error.reason == {:invalid_option, :algorithm, :aes_128}
  end

  test "rejects advisory permission values that are not lists" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: "open-secret",
               owner_password: "owner-secret",
               advisory_permissions: :print
             )

    assert error.stage == :protect
    assert error.reason == {:invalid_option, :advisory_permissions, :print}
    refute_receive {:fake_adapter_called, _}
  end

  test "rejects unknown advisory permissions" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: "open-secret",
               owner_password: "owner-secret",
               advisory_permissions: [:copy, :launch]
             )

    assert error.reason == {:unknown_permissions, [:launch]}
  end

  test "rejects extract_for_accessibility at the public boundary" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FakeAdapter,
               open_password: "open-secret",
               owner_password: "owner-secret",
               advisory_permissions: [:extract_for_accessibility]
             )

    assert error.stage == :protect
    assert error.reason == {:unknown_permissions, [:extract_for_accessibility]}
    refute_receive {:fake_adapter_called, _}
  end

  test "wraps adapter failures in a protect-stage Rendro.Error" do
    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: FailingAdapter,
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:adapter_failure, FailingAdapter, :adapter_down}
    assert error.details.has_open_password == true
    assert error.details.has_owner_password == true
    refute Map.has_key?(error.details, :open_password)
    refute Map.has_key?(error.details, :owner_password)
  end

  test "qpdf-backed failures redact passwords and runner output from the public error" do
    Application.put_env(:rendro, :qpdf_executable_finder, fn "qpdf" -> "/tmp/fake-qpdf" end)

    Application.put_env(:rendro, :qpdf_command_runner, fn "/tmp/fake-qpdf", [_argfile], _opts ->
      {"stderr mentions open-secret and owner-secret", 2}
    end)

    on_exit(fn ->
      Application.delete_env(:rendro, :qpdf_executable_finder)
      Application.delete_env(:rendro, :qpdf_command_runner)
    end)

    assert {:error, %Rendro.Error{} = error} =
             Protect.password(sample_artifact(),
               adapter: Qpdf,
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert error.stage == :protect
    assert error.reason == {:adapter_failure, Qpdf, {:qpdf_failed, 2}}
    refute error.why =~ "open-secret"
    refute error.why =~ "owner-secret"
    refute inspect(error.reason) =~ "open-secret"
    refute inspect(error.reason) =~ "owner-secret"
    refute inspect(error.details) =~ "open-secret"
    refute inspect(error.details) =~ "owner-secret"
  end

  test "render_protected/3 composes render_to_artifact and protect" do
    doc =
      Rendro.fixed([
        Rendro.page(blocks: [Rendro.block(Rendro.text("Protected", size: 12), x: 10, y: 20)])
      ])

    assert {:ok, %Artifact{} = artifact} =
             Protect.render_protected(doc, [deterministic: true],
               adapter: FakeAdapter,
               open_password: "open-secret",
               owner_password: "owner-secret"
             )

    assert artifact.metadata.deterministic == false

    assert artifact.metadata.protection == %{
             algorithm: :aes_256,
             advisory_permissions: [],
             has_open_password: true,
             has_owner_password: true
           }
  end
end
