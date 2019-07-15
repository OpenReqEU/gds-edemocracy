defmodule ExVoteWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ex_vote

  socket "/socket", ExVoteWeb.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :ex_vote, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Logger

  plug CORSPlug

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_ex_vote_key",
    signing_salt: "jtBpIbdt"

  plug ExVoteWeb.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("EXVOTE_PORT") || raise "expected the EXVOTE_PORT environment variable to be set"
      path = System.get_env("EXVOTE_PATH") || raise "expected the EXVOTE_PATH environment variable to be set"
      host = System.get_env("EXVOTE_HOST") || raise "expected the EXVOTE_HOST environment variable to be set"
      config =
        config
        |> Keyword.put(:http, [:inet6, port: port])
        |> Keyword.put(:url, [host: host, port: port, path: path])
      {:ok, config}
    else
      {:ok, config}
    end
  end
end
