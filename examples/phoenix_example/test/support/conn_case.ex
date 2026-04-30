defmodule PhoenixExampleWeb.ConnCase do
  @moduledoc """
  Test case template for controller tests.

  Sets up a Phoenix.ConnTest connection pre-wired to the example endpoint.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest

      import PhoenixExampleWeb.ConnCase

      @endpoint PhoenixExampleWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
