# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ex_vote,
  ecto_repos: [ExVote.Repo]

# Configures the endpoint
config :ex_vote, ExVoteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ACg1iJzVBHM7LwQQAObKtgqpfKikGczECDNnKNhQ8/cG45k+YwiPAqYqzEB44qBf",
  render_errors: [view: ExVoteWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ExVote.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :ex_vote, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: ExVoteWeb.Router]
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
