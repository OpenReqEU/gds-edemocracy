defmodule ExVoteWeb.Plugs.UserPlugs do
  require Logger
  import Plug.Conn

  def fetch_user(conn, _opts) do
    case get_session(conn, :user) do
      %ExVote.Accounts.User{} = user -> assign(conn, :user, user)
      _ -> assign(conn, :user, nil)
    end
  end

  def ensure_token(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, user_id} <- ExVoteWeb.Tokens.verify(token),
         user = ExVote.Accounts.get_user(user_id) do
      if user != nil do
        assign(conn, :user, user)
      else
        reject_token(conn, "User not found")
      end
    else
      {:error, :token_missing} -> reject_token(conn, "Token missing")
      {:error, :invalid} -> reject_token(conn, "Invalid token")
      {:error, :expired} -> reject_token(conn, "Token expired")
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      [] -> {:error, :token_missing}
      [token] -> {:ok, token}
    end
  end

  defp reject_token(conn, reason) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.json(%{error: reason})
    |> halt()
  end
end
