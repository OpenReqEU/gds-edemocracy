defmodule ExVoteWeb.Api.ProjectParticipationView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

  def render("participation.json", %{:participation => participation}) do
    participation_json(participation)
  end

  def render("participations.json", %{:participations => participations}) do
    Enum.map(participations, &participation_json/1)
  end

  def render("votes_users.json", %{:votes => votes}) do
    %{
      type: "participations",
      votes: Enum.map(votes, &user_json/1)
    }
  end

  def render("votes_tickets.json", %{:votes => votes}) do
    %{
      type: "tickets",
      votes: Enum.map(votes, &ticket_json/1)
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

  defp ticket_json(ticket) do
    %{
      id: ticket.id,
      external_id: ticket.external_id,
      title: ticket.title,
      description: ticket.description,
      url: ticket.url
    }
  end

  defp user_json(user) do
    %{
      id: user.id,
      name: user.name
    }
  end
end
