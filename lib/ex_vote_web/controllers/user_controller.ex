defmodule ExVoteWeb.UserController do
  use ExVoteWeb, :controller

  def login(%{:method => "GET"} = conn, _params) do
    # TODO: render form and stuff
    text(conn, "get")
  end

  def login(conn, params) do
    IO.inspect(conn)
    case ExVote.Accounts.login(params) do
      {:ok, user} ->
        conn
        |> assign(:user, user)
        |> put_session(:user, user)
        |> put_flash(:info, "Login success!")
      {:error, message} ->
        conn
        |> put_flash(:error, "Login failed with message: #{message}")
    end
  end
end
