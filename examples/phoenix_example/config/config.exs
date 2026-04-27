import Config

# Configures the endpoint
config :phoenix_example, PhoenixExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: PhoenixExampleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixExample.PubSub,
  live_view: [signing_salt: "rendro_dev_salt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
