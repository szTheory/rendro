defmodule Rendro.Adapters.PyHankoTest do
  use ExUnit.Case, async: false

  import Bitwise

  alias Rendro.Adapters.PyHanko
  alias Rendro.Artifact

  setup do
    on_exit(fn ->
      Application.delete_env(:rendro, :pyhanko_executable_finder)
      Application.delete_env(:rendro, :pyhanko_command_runner)
    end)

    :ok
  end

  defp sample_artifact do
    %Artifact{
      binary: "%PDF-sample",
      hash: Base.encode16(:crypto.hash(:sha256, "%PDF-sample"), case: :lower),
      diagnostics: [],
      metadata: %{page_count: 1}
    }
  end

  defp sample_opts do
    %{
      field: "customer_signature",
      adapter_opts: [
        key: "/tmp/test-key.pem",
        cert: "/tmp/test-cert.pem",
        passfile: "/tmp/test-pass.txt",
        chain: ["/tmp/intermediate.pem"],
        reason: "Approved"
      ]
    }
  end

  test "returns a typed error when pyhanko is missing" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> nil end)

    assert {:error, {:missing_executable, "pyhanko"}} =
             PyHanko.sign(sample_artifact(), sample_opts())
  end

  test "passes pemder args through a private temp directory and returns signed bytes" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path, output_path] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()

      assert file_mode(Path.dirname(input_path)) == 0o700
      assert file_mode(input_path) == 0o600
      assert Enum.take(args, 4) == ["sign", "addsig", "--field", "customer_signature"]
      assert Enum.member?(args, "pemder")
      assert Enum.member?(args, "--key")
      assert Enum.member?(args, "/tmp/test-key.pem")
      assert Enum.member?(args, "--cert")
      assert Enum.member?(args, "/tmp/test-cert.pem")
      assert Enum.member?(args, "--passfile")
      assert Enum.member?(args, "/tmp/test-pass.txt")
      assert Enum.member?(args, "--chain")
      assert Enum.member?(args, "/tmp/intermediate.pem")
      assert Enum.member?(args, "--reason")
      assert Enum.member?(args, "Approved")

      File.write!(output_path, "%PDF-signed")
      {"ok", 0}
    end)

    assert {:ok, "%PDF-signed", metadata} = PyHanko.sign(sample_artifact(), sample_opts())
    assert metadata.tool == :pyhanko
    assert metadata.credential_source == :pemder
    assert metadata.chain_count == 1
    assert metadata.passphrase_supplied == true
  end

  test "cleans up its temp directory and redacts stderr on non-zero exit" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    Application.put_env(:rendro, :pyhanko_command_runner, fn "/tmp/pyhanko", args, _opts ->
      [input_path | _] = Enum.take(Enum.reverse(args), 2) |> Enum.reverse()
      send(self(), {:tmp_dir, Path.dirname(input_path)})
      {"pyhanko failed for super-secret-passphrase", 2}
    end)

    assert {:error, {:pyhanko_failed, 2}} = PyHanko.sign(sample_artifact(), sample_opts())
    assert_receive {:tmp_dir, tmp_dir}
    refute File.exists?(tmp_dir)
  end

  test "validates required adapter-local options" do
    Application.put_env(:rendro, :pyhanko_executable_finder, fn "pyhanko" -> "/tmp/pyhanko" end)

    assert {:error, {:missing_required_adapter_option, :key}} =
             PyHanko.sign(sample_artifact(), %{
               field: "customer_signature",
               adapter_opts: [cert: "/tmp/cert.pem"]
             })

    assert {:error, {:invalid_adapter_option, :chain, :bad}} =
             PyHanko.sign(sample_artifact(), %{
               field: "customer_signature",
               adapter_opts: [key: "/tmp/key.pem", cert: "/tmp/cert.pem", chain: :bad]
             })
  end

  defp file_mode(path) do
    path
    |> File.stat!()
    |> Map.fetch!(:mode)
    |> band(0o777)
  end
end
