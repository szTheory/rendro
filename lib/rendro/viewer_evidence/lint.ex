defmodule Rendro.ViewerEvidence.Lint do
  @moduledoc false

  @byte_budget 65_536

  @evidence_body_patterns [
    {~r/-----BEGIN/, "PEM blocks are forbidden in evidence bodies"},
    {~r/!\[/, "Markdown image embeds are forbidden in evidence bodies"},
    {~r/<img/i, "HTML image tags are forbidden in evidence bodies"},
    {~r/data:image\//, "inline data URIs are forbidden in evidence bodies"},
    {~r/\/Users\//, "absolute home paths are forbidden in evidence bodies"},
    {~r/\/home\//, "absolute home paths are forbidden in evidence bodies"},
    {~r/C:\\Users\\/i, "absolute home paths are forbidden in evidence bodies"},
    {~r/(?<!\bno )(?<!\bwithout )passphrase\s*:/i,
     "operational passphrase assignments are forbidden in evidence bodies"},
    {~r/(?<!\bno )(?<!\bwithout )private_key\s*:/i,
     "operational private_key assignments are forbidden in evidence bodies"}
  ]

  @whole_reason_denylist ~r/^(?:tbd|not yet|deferred for later)$/i

  @allowlist_phrases [
    "does not yet implement",
    "not yet implemented",
    "not yet available in"
  ]

  @spec evidence_body(String.t()) :: {:ok, :clean} | {:error, String.t()}
  def evidence_body(body) do
    Enum.reduce_while(@evidence_body_patterns, {:ok, :clean}, fn {pattern, message}, _acc ->
      if Regex.match?(pattern, body) do
        {:halt, {:error, message}}
      else
        {:cont, {:ok, :clean}}
      end
    end)
  end

  @spec deferral_reason(String.t()) :: {:ok, :clean} | {:error, String.t()}
  def deferral_reason(reason) when is_binary(reason) do
    trimmed = String.trim(reason)

    cond do
      trimmed == "" ->
        {:error, "deferral reason must not be empty or whitespace"}

      String.length(trimmed) < 40 ->
        {:error, "deferral reason must be at least 40 characters after trimming"}

      Regex.match?(@whole_reason_denylist, trimmed) ->
        {:error, "deferral reason is too vague"}

      Regex.match?(~r/\bTBD\b/i, trimmed) ->
        {:error, "deferral reason must not contain TBD"}

      Regex.match?(~r/^deferred for later/i, trimmed) ->
        {:error, "deferral reason must not begin with 'deferred for later'"}

      allowlisted_phrase?(trimmed) ->
        {:ok, :clean}

      true ->
        {:ok, :clean}
    end
  end

  @spec byte_budget(String.t()) :: {:ok, :clean} | {:error, String.t()}
  def byte_budget(content) do
    if byte_size(content) > @byte_budget do
      {:error, "evidence file exceeds #{@byte_budget}-byte budget"}
    else
      {:ok, :clean}
    end
  end

  defp allowlisted_phrase?(text) do
    Enum.any?(@allowlist_phrases, &String.contains?(String.downcase(text), &1))
  end
end
