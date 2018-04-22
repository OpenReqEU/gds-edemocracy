defmodule ExVoteWeb.PageController do
  use ExVoteWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end
end
