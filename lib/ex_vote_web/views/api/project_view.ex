defmodule ExVoteWeb.Api.ProjectView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

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

  def render("tickets.json", %{:tickets => tickets}) do
    Enum.map(tickets, &ticket_json/1)
  end

  def render("users.json", %{:users => users}) do
    Enum.map(users, &user_json/1)
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
      external_id: ticket.external_id,
      title: ticket.title,
      description: ticket.description,
      url: ticket.url
    }
  end

  defp user_json(%ExVote.Accounts.User{} = user) do
    %{
      id: user.id,
      name: user.name
    }
  end
end
