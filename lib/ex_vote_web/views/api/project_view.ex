defmodule ExVoteWeb.Api.ProjectView do
  use ExVoteWeb, :view

  def render("show.json", %{:project => project}) do
    %{
      title: project.title,
      phase_candidates_at: project.phase_candidates,
      phase_end_at: project.phase_end,
      tickets: Enum.map(project.tickets, &ticket_json/1)
    }
  end

  def render("join.json", %{:participation => participation}) do
    participation_json(participation)
  end

  def render("error.json", %{:changeset => changeset}) do
    errors =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg,_opts} -> msg end)

    %{
      errors: Enum.map(errors, &error_json/1)
    }
  end

  defp ticket_json(ticket) do
    %{
      title: ticket.title,
      url: ticket.url
    }
  end

  defp participation_json(%ExVote.Participations.UserParticipation{} = participation) do
    %{
      project_id: participation.project_id,
      user_id: participation.user_id,
      role: participation.role
    }
  end

  defp participation_json(%ExVote.Participations.CandidateParticipation{} = participation) do
    %{
      project_id: participation.project_id,
      user_id: participation.user_id,
      role: participation.role,
      candidate_summary: participation.candidate_summary
    }
  end

end
