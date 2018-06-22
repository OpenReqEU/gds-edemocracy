defmodule ExVoteWeb.Plugs.ParticipationPlugs do
  import Plug.Conn

  alias ExVote.Participations

  def fetch_current_participation(conn, _opts) do
    participation =
      Participations.get_participation(conn.assigns[:project], conn.assigns[:user])

    assign(conn, :participation, participation)
  end
end
