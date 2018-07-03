defmodule ExVoteWeb.Api.RedocController do
  use ExVoteWeb, :controller

  def index(conn, _params) do
    conn
    |> html(File.read!("./priv/static/redoc.html"))
  end
end
