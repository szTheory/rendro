defmodule Rendro.ReleasePreflightProof do
  @moduledoc false

  def run(args, context \\ default_context()) do
    with {:ok, options} <- parse_args(args, context),
         :ok <- validate_options(options),
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
          current_version_tag: :boolean,
          candidate_sha: :string,
          skip_ci: :boolean,
          skip_security_audits: :boolean
        ],
        aliases: [r: :ref, w: :worktree]
      )

    cond do
      invalid != [] ->
        {:error,
         "invalid options: #{Enum.map_join(invalid, ", ", fn {key, _} -> "--#{key}" end)}"}

      is_nil(opts[:current_version_tag]) && is_nil(opts[:ref]) && is_nil(opts[:candidate_sha]) ->
        {:error, "missing required --ref vX.Y.Z, --current-version-tag, or --candidate-sha SHA"}

      is_nil(opts[:worktree]) ->
        {:error, "missing required --worktree PATH"}

      Enum.count([opts[:current_version_tag], opts[:ref], opts[:candidate_sha]], & &1) != 1 ->
        {:error, "use exactly one of --ref, --current-version-tag, or --candidate-sha"}

      opts[:candidate_sha] &&
          (Keyword.get(opts, :skip_ci, false) || Keyword.get(opts, :skip_security_audits, false)) ->
        {:error, "candidate SHA proof cannot bypass CI or security audits"}

      opts[:current_version_tag] ->
        {:ok,
         %{
           ref: current_version_tag(context),
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false),
           synthetic_tag: true,
           skip_ci: Keyword.get(opts, :skip_ci, false),
           skip_security_audits: Keyword.get(opts, :skip_security_audits, false)
         }}

      opts[:candidate_sha] ->
        {:ok,
         %{
           candidate_sha: opts[:candidate_sha],
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false),
           synthetic_tag: false,
           skip_ci: false,
           skip_security_audits: false
         }}

      true ->
        {:ok,
         %{
           ref: opts[:ref],
           worktree: opts[:worktree],
           dry_run: Keyword.get(opts, :dry_run, false),
           keep: Keyword.get(opts, :keep, false),
           synthetic_tag: false,
           skip_ci: Keyword.get(opts, :skip_ci, false),
           skip_security_audits: Keyword.get(opts, :skip_security_audits, false)
         }}
    end
  end

  def validate_ref("v" <> rest = ref) do
    if Regex.match?(~r/^\d+\.\d+\.\d+([-.][0-9A-Za-z.-]+)?$/, rest) do
      :ok
    else
      {:error, "ref must be an exact release tag like vX.Y.Z; got #{ref}"}
    end
  end

  def validate_ref(ref), do: {:error, "ref must be an exact release tag like vX.Y.Z; got #{ref}"}

  def validate_options(%{candidate_sha: candidate_sha}) when is_binary(candidate_sha) do
    if Regex.match?(~r/^[0-9a-f]{40}$/, candidate_sha),
      do: :ok,
      else: {:error, "candidate SHA must be 40 lowercase hex characters"}
  end

  def validate_options(%{ref: ref}), do: validate_ref(ref)

  def validate_worktree(worktree) do
    if Path.expand(worktree) == File.cwd!() do
      {:error, "worktree path must be isolated from the active workspace"}
    else
      :ok
    end
  end

  def execute_proof(options, context \\ default_context()) do
    if Map.has_key?(options, :candidate_sha) do
      execute_candidate_sha_proof(options, context)
    else
      execute_tag_proof(options, context)
    end
  end

  defp execute_tag_proof(options, context) do
    case maybe_prepare_synthetic_tag(options, context) do
      {:ok, cleanup_state} ->
        with {_, 0} <-
               run_command(context, "git", ["rev-parse", "--verify", "#{options.ref}^{commit}"]),
             {_, 0} <-
               run_command(context, "git", [
                 "worktree",
                 "add",
                 "--detach",
                 options.worktree,
                 options.ref
               ]),
             {deps_output, 0} <-
               run_command(context, "mix", ["deps.get"], cd: options.worktree),
             {preflight_output, status} <-
               run_command(context, "mix", release_preflight_args(options), cd: options.worktree),
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

  defp execute_candidate_sha_proof(options, context) do
    with {before_refs, 0} <- run_command(context, "git", ["show-ref", "--tags"]),
         {_, 0} <-
           run_command(context, "git", [
             "worktree",
             "add",
             "--detach",
             options.worktree,
             options.candidate_sha
           ]),
         {head, 0} <- run_command(context, "git", ["-C", options.worktree, "rev-parse", "HEAD"]),
         true <- String.trim(head) == options.candidate_sha,
         {deps_output, 0} <- run_command(context, "mix", ["deps.get"], cd: options.worktree),
         {preflight_output, status} <-
           run_command(context, "mix", release_preflight_args(options), cd: options.worktree),
         :ok <- cleanup(options, %{tag: nil, previous_target: nil}, context),
         {after_refs, 0} <- run_command(context, "git", ["show-ref", "--tags"]),
         true <- before_refs == after_refs do
      output = deps_output <> preflight_output

      if status == 0 do
        {:ok, output}
      else
        {:error, status, output}
      end
    else
      false ->
        cleanup(options, %{tag: nil, previous_target: nil}, context)
        {:error, 1, "candidate SHA or tag-ref snapshot mismatch"}

      {output, status} ->
        cleanup(options, %{tag: nil, previous_target: nil}, context)
        {:error, status, output}
    end
  end

  defp run_command(context, command, args, opts \\ []) do
    print_command(command, args, opts)
    context.runner.(command, args, Keyword.put(opts, :stderr_to_stdout, true))
  end

  defp print_command(command, args, opts) do
    cd = Keyword.get(opts, :cd)
    command_line = Enum.join([command | args], " ")

    if cd do
      IO.puts("$ cd #{cd} && #{command_line}")
    else
      IO.puts("$ #{command_line}")
    end
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
    %{runner: &streaming_system_cmd/3, project_config: Mix.Project.config()}
  end

  defp streaming_system_cmd(command, args, opts) do
    System.cmd(
      command,
      args,
      Keyword.put_new(opts, :into, %Rendro.Release.StreamingCommandCapture{})
    )
  end

  defp current_version_tag(context) do
    version = context.project_config[:version] || raise "missing Mix project version"
    "v#{version}"
  end

  defp release_preflight_args(options) do
    ["release.preflight"]
    |> maybe_add_candidate_sha(options)
    |> maybe_add_flag(options, :skip_ci, "--skip-ci")
    |> maybe_add_flag(options, :skip_security_audits, "--skip-security-audits")
  end

  defp maybe_add_candidate_sha(args, %{candidate_sha: candidate_sha}),
    do: args ++ ["--candidate-sha", candidate_sha]

  defp maybe_add_candidate_sha(args, _options), do: args

  defp dry_run_message(%{synthetic_tag: true, ref: ref, worktree: worktree} = options) do
    "Dry run: would create disposable exact tag #{ref} at HEAD, create isolated worktree #{worktree}, run mix deps.get and mix release.preflight#{proof_flag_suffix(options)}, then clean up"
  end

  defp dry_run_message(%{candidate_sha: candidate_sha, worktree: worktree} = options) do
    "Dry run: would create isolated detached worktree #{worktree} at exact SHA #{candidate_sha}, assert HEAD equality and unchanged tag refs, run mix deps.get and mix release.preflight#{proof_flag_suffix(options)}, then clean up"
  end

  defp dry_run_message(%{ref: ref, worktree: worktree} = options) do
    "Dry run: would create isolated worktree #{worktree} at #{ref}, run mix deps.get and mix release.preflight#{proof_flag_suffix(options)}, then clean up"
  end

  defp maybe_add_flag(args, options, key, flag) do
    if Map.get(options, key, false), do: args ++ [flag], else: args
  end

  defp proof_flag_suffix(options) do
    options
    |> release_preflight_args()
    |> tl()
    |> Enum.map_join("", &" #{&1}")
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
