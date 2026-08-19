defmodule Mix.Tasks.RendroGenThemeFreshConsumerTest do
  use ExUnit.Case, async: false

  test "a fresh local-path consumer discovers, compiles, and audits the generator contract" do
    root = File.cwd!()

    tmp =
      Path.join(System.tmp_dir!(), "rendro-fresh-consumer-#{System.unique_integer([:positive])}")

    consumer = Path.join(tmp, "consumer")
    File.mkdir_p!(tmp)

    try do
      run!(tmp, ["new", "consumer", "--sup"])
      add_local_dependency!(consumer, root)
      run!(consumer, ["deps.get"])
      run!(consumer, ["deps.compile", "rendro"])
      run!(consumer, ["compile"])
      baseline = tree(consumer)

      {default_output, 0} = run!(consumer, ["rendro.gen.theme", "swiss", "--accent", "#2C6BED"])
      assert default_output =~ "Generated lib/consumer/rendro_theme.ex"
      default = Path.join(consumer, "lib/consumer/rendro_theme.ex")
      assert File.read!(default) =~ "defmodule Consumer.RendroTheme"

      assert (tree(consumer) -- baseline) |> Enum.map(&elem(&1, 0)) == [
               "lib/consumer/rendro_theme.ex"
             ]

      explicit = Path.join(consumer, "lib/consumer/brand/theme.ex")

      {explicit_output, 0} =
        run!(consumer, [
          "rendro.gen.theme",
          "humanist",
          "--accent",
          "#147A4B",
          "--module",
          "Consumer.Brand.Theme",
          "--out",
          "lib/consumer/brand/theme.ex"
        ])

      assert explicit_output =~ "Generated lib/consumer/brand/theme.ex"
      assert File.regular?(explicit)
      source = File.read!(explicit)
      File.write!(explicit, "# detached policy\n")
      before_conflict = tree(consumer)

      {conflict, 0} =
        run!(
          consumer,
          [
            "rendro.gen.theme",
            "humanist",
            "--accent",
            "#147A4B",
            "--module",
            "Consumer.Brand.Theme",
            "--out",
            "lib/consumer/brand/theme.ex"
          ]
        )

      assert conflict =~ "Skipped lib/consumer/brand/theme.ex"
      assert File.read!(explicit) == "# detached policy\n"
      assert tree(consumer) == before_conflict

      {force_output, 0} =
        run!(consumer, [
          "rendro.gen.theme",
          "humanist",
          "--accent",
          "#147A4B",
          "--module",
          "Consumer.Brand.Theme",
          "--out",
          "lib/consumer/brand/theme.ex",
          "--force"
        ])

      assert force_output =~ "Generated lib/consumer/brand/theme.ex"
      assert File.read!(explicit) == source

      equal_before = tree(consumer)

      {equal, 0} =
        run!(consumer, [
          "rendro.gen.theme",
          "humanist",
          "--accent",
          "#147A4B",
          "--module",
          "Consumer.Brand.Theme",
          "--out",
          "lib/consumer/brand/theme.ex",
          "--check"
        ])

      assert equal =~ "--check: OK"
      assert tree(consumer) == equal_before

      File.write!(explicit, "# drift\n")
      drift_before = tree(consumer)

      {different, 1} =
        run!(consumer, [
          "rendro.gen.theme",
          "humanist",
          "--accent",
          "#147A4B",
          "--module",
          "Consumer.Brand.Theme",
          "--out",
          "lib/consumer/brand/theme.ex",
          "--check"
        ])

      assert different =~ "bytes differ"
      assert different =~ "Next: mix rendro.gen.theme"
      assert tree(consumer) == drift_before

      {missing, 1} =
        run!(consumer, [
          "rendro.gen.theme",
          "swiss",
          "--accent",
          "#2C6BED",
          "--out",
          "lib/consumer/missing/theme.ex",
          "--check"
        ])

      assert missing =~ "file is missing"
      refute File.exists?(Path.join(consumer, "lib/consumer/missing"))
    after
      File.rm_rf!(tmp)
    end
  end

  defp add_local_dependency!(consumer, root) do
    mix = Path.join(consumer, "mix.exs")
    contents = File.read!(mix)
    dependency = "{:rendro, path: #{inspect(root)}},"

    updated =
      String.replace(contents, "defp deps do\n    [", "defp deps do\n    [\n      #{dependency}")

    assert updated != contents
    File.write!(mix, updated)
  end

  defp run!(cwd, ["rendro.gen.theme" | task_args]) do
    source =
      "Code.ensure_loaded!(Mix.Tasks.Rendro.Gen.Theme); Mix.Task.run(\"rendro.gen.theme\", #{inspect(task_args)})"

    System.cmd("mix", ["run", "--no-start", "-e", source],
      cd: cwd,
      stderr_to_stdout: true
    )
  end

  defp run!(cwd, args) do
    {output, status} = System.cmd("mix", args, cd: cwd, stderr_to_stdout: true)

    {output, status}
  end

  defp tree(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(
      &(Path.basename(&1) in [".", ".."] or String.contains?(&1, "/_build/") or
          String.contains?(&1, "/deps/"))
    )
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(fn file ->
      relative = Path.relative_to(file, root)
      stat = File.stat!(file)
      {relative, stat.type, stat.mtime, :crypto.hash(:sha256, File.read!(file))}
    end)
    |> Enum.sort()
  end
end
