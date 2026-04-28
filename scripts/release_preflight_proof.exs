defmodule Rendro.ReleasePreflightProof do
  @moduledoc false

  def run(args, context \\ default_context()) do
    with {:ok, options} <- parse_args(args),
         :ok <- validate_ref(options.ref),
         :ok <- validate_worktree(options.worktree) do
      if options.dry_run do
        Mix.shell().info(
          "Dry run: would create isolated worktree #{options.worktree} at #{options.ref} and run mix release.preflight"
        )

        :ok
      else
        execute_proof(options, context)
      end
    else
      {:error, message} ->
        Mix.shell().error(message)
        System.halt(1)
    end
  end

  def parse_args(args) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [ref: :string, worktree: :string, dry_run: :boolean, keep: :boolean],
        aliases: [r: :ref, w: :worktree]
      )

    cond do
      invalid != [] ->
        {:error,
         "invalid options: #{Enum.map_join(invalid, ", ", fn {key, _} -> "--#{key}" end)}"}

      is_nil(opts[:ref]) ->
        {:error, "missing required --ref vX.Y.Z"}

      is_nil(opts[:worktree]) ->
        {:error, "missing required --worktree PATH"}

      true ->
        {:ok,
         %{
           ref: opts[:ref],
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false)
         }}
    end
  end

  def validate_ref("v" <> rest = ref) do
    if Regex.match?(~r/^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$/, rest) do
      :ok
    else
      {:error, "ref must be an exact release tag like v0.1.0; got #{ref}"}
    end
  end

  def validate_ref(ref), do: {:error, "ref must be an exact release tag like v0.1.0; got #{ref}"}

  def validate_worktree(worktree) do
    if Path.expand(worktree) == File.cwd!() do
      {:error, "worktree path must be isolated from the active workspace"}
    else
      :ok
    end
  end

  defp execute_proof(options, context) do
    with {_, 0} <-
           context.runner.("git", ["rev-parse", "--verify", "#{options.ref}^{commit}"],
             stderr_to_stdout: true
           ),
         {_, 0} <-
           context.runner.("git", ["worktree", "add", "--detach", options.worktree, options.ref],
             stderr_to_stdout: true
           ),
         {output, status} <-
           context.runner.("mix", ["release.preflight"],
             cd: options.worktree,
             stderr_to_stdout: true
           ),
         :ok <- maybe_cleanup(options, context) do
      IO.write(output)

      if status == 0 do
        :ok
      else
        System.halt(status)
      end
    else
      {output, status} ->
        Mix.shell().error(output)
        maybe_cleanup(options, context)
        System.halt(status)
    end
  end

  defp maybe_cleanup(%{keep: true}, _context), do: :ok

  defp maybe_cleanup(%{worktree: worktree}, context) do
    _ =
      context.runner.("git", ["worktree", "remove", "--force", worktree], stderr_to_stdout: true)

    :ok
  end

  defp default_context do
    %{runner: &System.cmd/3}
  end
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  Rendro.ReleasePreflightProof.run(System.argv())
end
