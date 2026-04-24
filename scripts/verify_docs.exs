# verify_docs.exs
# Extracts Elixir code blocks from README.md and ensures they compile

readme = File.read!("README.md")
code_blocks = Regex.scan(~r/```elixir\n(.*?)```/s, readme)

Mix.shell().info("Verifying code blocks in README.md...")

Enum.each(code_blocks, fn [_, code] ->
  try do
    Code.compile_string(code)
    Mix.shell().info("  - Code block compiles: OK")
  rescue
    e ->
      Mix.shell().error("  - Code block failed to compile:\n#{code}\n#{inspect(e)}")
      System.halt(1)
  end
end)

Mix.shell().info("Docs contract VERIFIED!")
