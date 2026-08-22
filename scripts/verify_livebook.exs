case System.argv() do
  [notebook_path, output_path] ->
    Application.put_env(:livebook, LivebookWeb.Endpoint, live_reload: [])
    Application.put_env(:livebook, Livebook.Apps.Manager, retry_backoff_base_ms: 5_000)
    Mix.install([{:livebook, "~> 0.19.9"}])

    notebook_path
    |> File.read!()
    |> Livebook.live_markdown_to_elixir()
    |> then(&File.write!(output_path, &1))

  _ ->
    raise ArgumentError, "usage: elixir scripts/verify_livebook.exs NOTEBOOK_PATH OUTPUT_PATH"
end
