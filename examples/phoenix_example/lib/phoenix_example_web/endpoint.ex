defmodule PhoenixExampleWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_example

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug PhoenixExampleWeb.Router
end
