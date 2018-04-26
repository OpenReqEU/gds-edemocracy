defmodule ExVoteWeb.Plugs.UserPlugs do
  require Logger
  import Plug.Conn

  def fetch_user(conn, _) do
    case get_session(conn, :user) do
      %ExVote.Accounts.User{} = user -> assign(conn, :user, user)
      _ -> assign(conn, :user, nil)
    end
  end
end
