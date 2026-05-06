defmodule Rendro.Protect do
  @moduledoc """
  Artifact-first PDF protection boundary.

  This surface leaves the core render pipeline unchanged. Callers render to a
  `%Rendro.Artifact{}` first and then apply a protection adapter such as
  `Rendro.Adapters.Qpdf`.
  """

  alias Rendro.{Artifact, Error}

  @default_adapter Rendro.Adapters.Qpdf
  @supported_permissions [
    :annotate,
    :assemble,
    :copy,
    :fill_forms,
    :modify,
    :print
  ]

  @type permission ::
          :print
          | :copy
          | :modify
          | :annotate
          | :fill_forms
          | :assemble

  @type option ::
          {:adapter, module()}
          | {:algorithm, :aes_256}
          | {:open_password, String.t()}
          | {:owner_password, String.t()}
          | {:advisory_permissions, [permission()]}

  @type options :: [option()]

  @spec password(Artifact.t(), options()) :: {:ok, Artifact.t()} | {:error, Error.t()}
  def password(%Artifact{} = artifact, opts) when is_list(opts) do
    with {:ok, normalized} <- normalize_opts(opts),
         {:ok, protected_binary} <- normalized.adapter.protect(artifact, normalized) do
      {:ok,
       Artifact.wrap(
         protected_binary,
         artifact,
         %{
           deterministic: false,
           protection: protection_metadata(normalized)
         }
       )}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.from_stage(
           :protect,
           {:adapter_failure, normalized_adapter(opts), reason},
           %{details: redact_opts(opts)}
         )}
    end
  end

  def password(%Artifact{}, opts) do
    {:error, Error.from_stage(:protect, {:invalid_option, :options, opts}, %{})}
  end

  @spec render_protected(Rendro.Document.t(), Rendro.render_options(), options()) ::
          {:ok, Artifact.t()} | {:error, Error.t()}
  def render_protected(%Rendro.Document{} = doc, render_opts \\ [], protect_opts)
      when is_list(render_opts) and is_list(protect_opts) do
    Rendro.render_protected(doc, render_opts, protect_opts)
  end

  @spec redact_opts(options() | map()) :: map()
  def redact_opts(opts) when is_list(opts) do
    opts
    |> Enum.into(%{})
    |> redact_opts()
  end

  def redact_opts(opts) when is_map(opts) do
    permissions =
      opts
      |> Map.get(:advisory_permissions, [])
      |> List.wrap()
      |> Enum.uniq()
      |> Enum.sort()

    %{
      adapter: Map.get(opts, :adapter, @default_adapter),
      algorithm: Map.get(opts, :algorithm, :aes_256),
      advisory_permissions: permissions,
      has_open_password: present_password?(Map.get(opts, :open_password)),
      has_owner_password: present_password?(Map.get(opts, :owner_password))
    }
  end

  @spec supported_permissions() :: [permission()]
  def supported_permissions, do: @supported_permissions

  defp normalize_opts(opts) do
    with {:ok, adapter} <- fetch_adapter(opts),
         {:ok, algorithm} <- fetch_algorithm(opts),
         {:ok, open_password} <- fetch_password(opts, :open_password),
         {:ok, owner_password} <- fetch_password(opts, :owner_password),
         {:ok, permissions} <- fetch_permissions(opts) do
      {:ok,
       %{
         adapter: adapter,
         algorithm: algorithm,
         advisory_permissions: permissions,
         open_password: open_password,
         owner_password: owner_password
       }}
    end
  end

  defp fetch_adapter(opts) do
    adapter = Keyword.get(opts, :adapter, @default_adapter)

    cond do
      not is_atom(adapter) ->
        {:error, Error.from_stage(:protect, {:invalid_option, :adapter, adapter}, %{})}

      not Code.ensure_loaded?(adapter) ->
        {:error, Error.from_stage(:protect, {:invalid_option, :adapter, adapter}, %{})}

      not function_exported?(adapter, :protect, 2) ->
        {:error, Error.from_stage(:protect, {:invalid_option, :adapter, adapter}, %{})}

      true ->
        {:ok, adapter}
    end
  end

  defp fetch_algorithm(opts) do
    case Keyword.get(opts, :algorithm, :aes_256) do
      :aes_256 -> {:ok, :aes_256}
      value -> {:error, Error.from_stage(:protect, {:invalid_option, :algorithm, value}, %{})}
    end
  end

  defp fetch_password(opts, key) do
    case Keyword.fetch(opts, key) do
      :error ->
        {:error, Error.from_stage(:protect, {:missing_required_option, key}, %{})}

      {:ok, value} when is_binary(value) ->
        cond do
          String.trim(value) == "" ->
            {:error, Error.from_stage(:protect, {:invalid_option, key, :empty}, %{})}

          String.contains?(value, ["\n", "\r", <<0>>]) ->
            {:error,
             Error.from_stage(:protect, {:invalid_option, key, :unsafe_characters}, %{})}

          true ->
            {:ok, value}
        end

      {:ok, value} ->
        {:error, Error.from_stage(:protect, {:invalid_option, key, value}, %{})}
    end
  end

  defp fetch_permissions(opts) do
    case Keyword.get(opts, :advisory_permissions, []) do
      permissions when is_list(permissions) ->
        normalized =
          permissions
          |> Enum.uniq()
          |> Enum.sort()

        unknown = normalized -- @supported_permissions

        if unknown == [] do
          {:ok, normalized}
        else
          {:error, Error.from_stage(:protect, {:unknown_permissions, unknown}, %{})}
        end

      value ->
        {:error, Error.from_stage(:protect, {:invalid_option, :advisory_permissions, value}, %{})}
    end
  end

  defp protection_metadata(opts) do
    %{
      algorithm: opts.algorithm,
      has_open_password: true,
      has_owner_password: true,
      advisory_permissions: opts.advisory_permissions
    }
  end

  defp normalized_adapter(opts) when is_list(opts),
    do: Keyword.get(opts, :adapter, @default_adapter)

  defp normalized_adapter(_opts), do: @default_adapter

  defp present_password?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_password?(_value), do: false
end
