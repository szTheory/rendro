defmodule Rendro.ReleasePreflightProof do
  @moduledoc false

  def run(args, context \\ default_context()) do
    with {:ok, options} <- parse_args(args, context),
         :ok <- validate_ref(options.ref),
         :ok <- validate_worktree(options.worktree) do
      if options.dry_run do
        Mix.shell().info(dry_run_message(options))

        :ok
      else
        case execute_proof(options, context) do
          {:ok, output} ->
            IO.write(output)
            :ok

          {:error, status, output} ->
            Mix.shell().error(output)
            System.halt(status)
        end
      end
    else
      {:error, message} ->
        Mix.shell().error(message)
        System.halt(1)
    end
  end

  def parse_args(args, context \\ default_context()) do
    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [
          ref: :string,
          worktree: :string,
          dry_run: :boolean,
          keep: :boolean,
          current_version_tag: :boolean
        ],
        aliases: [r: :ref, w: :worktree]
      )

    cond do
      invalid != [] ->
        {:error,
         "invalid options: #{Enum.map_join(invalid, ", ", fn {key, _} -> "--#{key}" end)}"}

      !opts[:current_version_tag] && is_nil(opts[:ref]) ->
        {:error, "missing required --ref vX.Y.Z or --current-version-tag"}

      is_nil(opts[:worktree]) ->
        {:error, "missing required --worktree PATH"}

      opts[:current_version_tag] && opts[:ref] ->
        {:error, "use either --ref vX.Y.Z or --current-version-tag, not both"}

      opts[:current_version_tag] ->
        {:ok,
         %{
           ref: current_version_tag(context),
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false),
           synthetic_tag: true
         }}

      true ->
        {:ok,
         %{
           ref: opts[:ref],
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false),
           synthetic_tag: false
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

  def execute_proof(options, context \\ default_context()) do
    case maybe_prepare_synthetic_tag(options, context) do
      {:ok, cleanup_state} ->
        with {_, 0} <-
               run_command(context, "git", ["rev-parse", "--verify", "#{options.ref}^{commit}"]),
             {_, 0} <-
               run_command(context, "git", ["worktree", "add", "--detach", options.worktree, options.ref]),
             {deps_output, 0} <-
               run_command(context, "mix", ["deps.get"], cd: options.worktree),
             {preflight_output, status} <-
               run_command(context, "mix", ["release.preflight"], cd: options.worktree),
             :ok <- cleanup(options, cleanup_state, context) do
          output = deps_output <> preflight_output

          if status == 0 do
            {:ok, output}
          else
            {:error, status, output}
          end
        else
          {output, status} ->
            cleanup(options, cleanup_state, context)
            {:error, status, output}
        end

      {:error, message} ->
        {:error, 1, message}
    end
  end

  defp run_command(context, command, args, opts \\ []) do
    context.runner.(command, args, Keyword.put(opts, :stderr_to_stdout, true))
  end

  defp maybe_prepare_synthetic_tag(%{synthetic_tag: false}, _context),
    do: {:ok, %{tag: nil, previous_target: nil}}

  defp maybe_prepare_synthetic_tag(%{ref: ref, synthetic_tag: true}, context) do
    previous_target =
      case run_command(context, "git", ["rev-parse", "--verify", "refs/tags/#{ref}^{commit}"]) do
        {sha, 0} -> String.trim(sha)
        _ -> nil
      end

    case run_command(context, "git", ["tag", "-f", ref, "HEAD"]) do
      {_output, 0} -> {:ok, %{tag: ref, previous_target: previous_target}}
      {output, _status} -> {:error, output}
    end
  end

  defp default_context do
    %{runner: &System.cmd/3, project_config: Mix.Project.config()}
  end

  defp current_version_tag(context) do
    version = context.project_config[:version] || raise "missing Mix project version"
    "v#{version}"
  end

  defp dry_run_message(%{synthetic_tag: true, ref: ref, worktree: worktree}) do
    "Dry run: would create disposable exact tag #{ref} at HEAD, create isolated worktree #{worktree}, run mix deps.get and mix release.preflight, then clean up"
  end

  defp dry_run_message(%{ref: ref, worktree: worktree}) do
    "Dry run: would create isolated worktree #{worktree} at #{ref}, run mix deps.get and mix release.preflight, then clean up"
  end

  defp cleanup(options, cleanup_state, context) do
    maybe_cleanup_worktree(options, context)
    maybe_cleanup_tag(cleanup_state, context)
    :ok
  end

  defp maybe_cleanup_worktree(%{keep: true}, _context), do: :ok

  defp maybe_cleanup_worktree(%{worktree: worktree}, context) do
    _ = run_command(context, "git", ["worktree", "remove", "--force", worktree])
    :ok
  end

  defp maybe_cleanup_tag(%{tag: nil}, _context), do: :ok

  defp maybe_cleanup_tag(%{tag: tag, previous_target: nil}, context) do
    _ = run_command(context, "git", ["tag", "-d", tag])
    :ok
  end

  defp maybe_cleanup_tag(%{tag: tag, previous_target: previous_target}, context) do
    _ = run_command(context, "git", ["tag", "-f", tag, previous_target])
    :ok
  end
end

unless Code.ensure_loaded?(ExUnit.Server) and Process.whereis(ExUnit.Server) do
  Rendro.ReleasePreflightProof.run(System.argv())
end
