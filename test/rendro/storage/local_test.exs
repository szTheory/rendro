defmodule Rendro.Storage.LocalTest do
  use ExUnit.Case, async: true

  alias Rendro.{Artifact, Protect}
  alias Rendro.Storage.Local

  defmodule FakeProtectAdapter do
    @behaviour Rendro.Protect.Adapter

    @impl true
    def protect(%Artifact{binary: binary}, _opts), do: {:ok, binary <> "::protected"}
  end

  test "plain artifacts round-trip through local storage" do
    path = tmp_path("plain.pdf")
    artifact = sample_artifact()

    assert {:ok, ^path} = Local.put(artifact, path: path)
    assert {:ok, %Artifact{} = reloaded} = Local.get(path, [])
    assert reloaded.binary == artifact.binary
    assert reloaded.hash == artifact.hash
    assert reloaded.metadata == %{}

    assert :ok = Local.delete(path, [])
    refute File.exists?(path)
  end

  test "protected artifacts preserve truthful protection metadata without persisting secrets" do
    path = tmp_path("protected.pdf")

    {:ok, protected} =
      Protect.password(sample_artifact(),
        adapter: FakeProtectAdapter,
        open_password: "open-secret",
        owner_password: "owner-secret",
        advisory_permissions: [:copy, :print]
      )

    assert {:ok, ^path} = Local.put(protected, path: path)
    assert {:ok, %Artifact{} = reloaded} = Local.get(path, [])

    assert reloaded.binary == protected.binary
    assert reloaded.hash == protected.hash
    assert reloaded.metadata.deterministic == false

    assert reloaded.metadata.protection == %{
             algorithm: :aes_256,
             advisory_permissions: [:copy, :print],
             has_open_password: true,
             has_owner_password: true
           }

    sidecar = File.read!(sidecar_path(path))
    refute sidecar =~ "open-secret"
    refute sidecar =~ "owner-secret"
    refute sidecar =~ "open_password"
    refute sidecar =~ "owner_password"
  end

  test "delete removes both the artifact and sidecar" do
    path = tmp_path("delete.pdf")

    {:ok, protected} =
      Protect.password(sample_artifact(),
        adapter: FakeProtectAdapter,
        open_password: "open-secret",
        owner_password: "owner-secret"
      )

    assert {:ok, ^path} = Local.put(protected, path: path)
    assert File.exists?(path)
    assert File.exists?(sidecar_path(path))

    assert :ok = Local.delete(path, [])
    refute File.exists?(path)
    refute File.exists?(sidecar_path(path))
  end

  test "byte-only fallback still returns a usable artifact" do
    path = tmp_path("bytes-only.pdf")
    binary = "%PDF-1.7\nbyte-only"

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, binary)

    assert {:ok, %Artifact{} = artifact} = Local.get(path, [])
    assert artifact.binary == binary
    assert artifact.hash == Base.encode16(:crypto.hash(:sha256, binary), case: :lower)
    assert artifact.metadata == %{}
  end

  defp sample_artifact do
    %Artifact{
      binary: "%PDF-sample",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-sample"), case: :lower),
      diagnostics: [%{type: :info}],
      metadata: %{page_count: 1, deterministic: true}
    }
  end

  defp tmp_path(filename) do
    base = Path.join(System.tmp_dir!(), "rendro-local-#{System.unique_integer([:positive])}")
    path = Path.join(base, filename)
    on_exit(fn -> File.rm_rf(base) end)
    path
  end

  defp sidecar_path(path), do: path <> ".metadata.json"
end
