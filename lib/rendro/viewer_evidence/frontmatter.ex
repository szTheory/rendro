defmodule Rendro.ViewerEvidence.Frontmatter do
  @moduledoc false

  @spec parse(String.t()) :: {:ok, {map(), String.t()}} | {:error, String.t()}
  def parse(content) do
    case String.split(content, "---", parts: 3) do
      ["", yaml, body | _] ->
        case YamlElixir.read_from_string(yaml) do
          {:ok, frontmatter} when is_map(frontmatter) ->
            {:ok, {frontmatter, String.trim_leading(body, "\n")}}

          {:ok, _} ->
            {:error, "frontmatter must decode to a YAML mapping"}

          {:error, reason} ->
            {:error, "invalid YAML frontmatter: #{inspect(reason)}"}
        end

      _ ->
        {:error, "evidence file must begin with YAML frontmatter fences"}
    end
  end

  @spec path_alignment(map(), String.t()) :: :ok | {:error, String.t()}
  def path_alignment(frontmatter, path) do
    with {:ok, surface} <- fetch_string(frontmatter, "surface"),
         {:ok, viewer} <- fetch_string(frontmatter, "viewer"),
         {:ok, {path_surface, path_viewer}} <- path_segments(path) do
      cond do
        surface != path_surface ->
          {:error,
           "frontmatter surface #{inspect(surface)} does not match path segment #{inspect(path_surface)}"}

        viewer != path_viewer ->
          {:error,
           "frontmatter viewer #{inspect(viewer)} does not match path segment #{inspect(path_viewer)}"}

        true ->
          :ok
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, "frontmatter #{key} must be a non-empty string"}
    end
  end

  defp path_segments(path) do
    case Regex.run(~r|^priv/viewer_evidence/([a-z0-9_]+)/([a-z0-9_]+)\.md$|, path) do
      [_, surface, viewer] -> {:ok, {surface, viewer}}
      _ -> {:error, "evidence path must match priv/viewer_evidence/<surface>/<viewer>.md"}
    end
  end
end
