defmodule ExVoteWeb.Plugs.UserPlugs do
  import Plug.Conn
  import Logger

  def fetch_user(conn, _) do
    case get_session(conn, :user) do
      %ExVote.Accounts.User{} = user -> assign(conn, :user, user)
      _ -> assign(conn, :user, nil)
    end
  end
end
