defmodule ExVoteWeb.Api.ProjectView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

  def render("index.json", %{:projects => projects}) do
    Enum.map(projects, &short_project_json/1)
  end

  def render("show.json", %{:project => project}) do
    %{
      id: project.id,
      title: project.title,
      phase_candidates_at: project.phase_candidates,
      phase_end_at: project.phase_end,
      tickets: Enum.map(project.tickets, &ticket_json/1)
    }
  end

  def render("report.json", %{:report => report}) do
    report = Map.from_struct(report)

    {_, report} =
      report
      |> get_and_update_in([:votes, :candidates], fn votes ->
        new_votes =
          votes
          |> Enum.map(fn %{candidate: user} = container ->
            %{container | candidate: user_json(user)}
          end)

        {votes, new_votes}
      end)

    {_, report} =
      report
      |> get_and_update_in([:votes, :tickets], fn votes ->
        new_votes =
          votes
          |> Enum.map(fn %{ticket: ticket} = container ->
            %{container | ticket: ticket_json(ticket)}
          end)

        {votes, new_votes}
      end)

    report
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
