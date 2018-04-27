defmodule ExVoteWeb.ApiView do
  use ExVoteWeb, :view

  def render("view.json", %{:project => project}) do
    %{
      title: project.title,
      current_phase: project.current_phase,
      phase_candidates_at: project.phase_candidates,
      phase_end_at: project.phase_end,
      tickets: Enum.map(project.tickets, &ticket_json/1)
    }
  end

  defp ticket_json(ticket) do
    %{
      title: ticket.title,
      url: ticket.url
    }
  end

end
