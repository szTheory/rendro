defmodule Rendro.Rules.CheckFormFields do
  @moduledoc false

  def check(%Rendro.FormField{name: name}, _doc) when is_binary(name) and byte_size(name) > 0,
    do: :ok

  def check(%Rendro.FormField{}, _doc), do: {:error, {:missing_required_key, :name}}

  def check(_, _doc), do: :ok
end
