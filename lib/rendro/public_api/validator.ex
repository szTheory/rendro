defmodule Rendro.PublicApi.Validator do
  @moduledoc false

  @schema_path "priv/schemas/public_api.schema.json"

  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(manifest) do
    schema = @schema_path |> File.read!() |> JSON.decode!() |> JSV.build!()

    case JSV.validate(manifest, schema) do
      {:ok, _} -> :ok
      {:error, err} -> {:error, format_jsv_error(err)}
    end
  end

  defp format_jsv_error(err) do
    err
    |> JSV.normalize_error()
    |> inspect(limit: :infinity)
  end
end
