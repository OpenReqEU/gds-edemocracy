defmodule ExVoteWeb.Api.ProjectView do
  use ExVoteWeb, :view

  def render("index.json", %{:projects => projects}) do
    Enum.map(projects, &short_project_json/1)
  end

  def render("show.json", %{:project => project}) do
    %{
      title: project.title,
      phase_candidates_at: project.phase_candidates,
      phase_end_at: project.phase_end,
      tickets: Enum.map(project.tickets, &ticket_json/1)
    }
  end

  def render("participation.json", %{:participation => participation}) do
    participation_json(participation)
  end

  def render("candidates.json", %{:candidates => candidates}) do
    Enum.map(candidates, &participation_json/1)
  end

  def render("tickets.json", %{:tickets => tickets}) do
    Enum.map(tickets, &ticket_json/1)
  end

  def render("error.json", %{:changeset => changeset}) do
    errors =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)

    %{
      errors: Enum.map(errors, &error_json/1)
    }
  end

  defp short_project_json(%ExVote.Projects.Project{} = project) do
    %{
      id: project.id,
      title: project.title,
      current_phase: project.current_phase
    }
  end

  defp ticket_json(ticket) do
    %{
      id: ticket.id,
      title: ticket.title,
      url: ticket.url
    }
  end

  defp participation_json(%ExVote.Participations.UserParticipation{} = participation) do
    %{
      name: participation.user.name,
      project_id: participation.project_id,
      user_id: participation.user_id,
      role: participation.role
    }
  end

  defp participation_json(%ExVote.Participations.CandidateParticipation{} = participation) do
    %{
      name: participation.user.name,
      project_id: participation.project_id,
      user_id: participation.user_id,
      role: participation.role,
      candidate_summary: participation.candidate_summary
    }
  end

end
