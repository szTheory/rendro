defmodule Rendro.Rules.CheckLinks do
  @moduledoc false

  alias Rendro.{Document, FormField, Link}

  @allowed_schemes ["http", "https"]

  def check(%Document{}, _doc), do: :ok

  def check(%Link{content: %FormField{}, target: _target}, _doc),
    do: {:error, {:unsupported_link_content, :form_field}}

  def check(%Link{target: {:uri, uri}}, _doc) when is_binary(uri) do
    validate_uri(uri)
  end

  def check(%Link{target: {:page, page_number}}, %Document{} = doc) when is_integer(page_number) do
    if page_number > 0 and page_number <= length(doc.pages) do
      :ok
    else
      {:error, {:invalid_link_page, page_number}}
    end
  end

  def check(%Link{target: {:page, page_number}}, _doc), do: {:error, {:invalid_link_page, page_number}}
  def check(%Link{target: target}, _doc), do: {:error, {:invalid_link_target, target}}
  def check(_, _doc), do: :ok

  defp validate_uri(uri) do
    case URI.new(uri) do
      {:ok, %URI{scheme: scheme, host: host}}
      when scheme in @allowed_schemes and is_binary(host) and byte_size(host) > 0 ->
        :ok

      {:ok, %URI{scheme: scheme}} when scheme in @allowed_schemes ->
        {:error, {:invalid_link_uri, uri}}

      {:ok, %URI{scheme: scheme}} when is_binary(scheme) ->
        {:error, {:unsupported_link_scheme, scheme}}

      {:ok, _uri} ->
        {:error, {:invalid_link_uri, uri}}

      {:error, _reason} ->
        {:error, {:invalid_link_uri, uri}}
    end
  end
end
