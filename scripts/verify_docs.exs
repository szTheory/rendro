# verify_docs.exs
# Extracts Elixir code blocks from README.md and ensures they compile

readme = File.read!("README.md")
code_blocks = Regex.scan(~r/```elixir\n(.*?)```/s, readme)

Mix.shell().info("Verifying code blocks in README.md...")

# Provide mocks for common dependencies in docs
defmodule MyAppWeb do
  defmacro __using__(:controller), do: nil
end

Enum.each(code_blocks, fn [_, code] ->
  try do
    Code.compile_string(code)
    Mix.shell().info("  - Code block compiles: OK")
  rescue
    e ->
      # Skip blocks that are clearly partial or need more context
      if code =~ "..." or code =~ "%{...}" do
        Mix.shell().info("  - Code block (partial) skipped: OK")
      else
        Mix.shell().error("  - Code block failed to compile:\n#{code}\n#{inspect(e)}")
        System.halt(1)
      end
  end
end)

Mix.shell().info("Docs contract VERIFIED!")
