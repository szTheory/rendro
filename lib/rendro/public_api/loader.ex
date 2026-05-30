defmodule Rendro.PublicApi.Loader do
  @moduledoc false

  @manifest_path "priv/public_api.json"

  @spec load!() :: map()
  def load! do
    @manifest_path |> File.read!() |> JSON.decode!()
  end
end
