defmodule ExVoteWeb.ProjectView do
  use ExVoteWeb, :view

  def format_date(date) do
    Timex.format!(date, "{relative}", :relative)
  end

  def time_to_next_phase(project) do
    next_phase_date = ExVote.Projects.Project.next_phase_at(project)

    if next_phase_date do
      Timex.format!(next_phase_date, "{relative}", :relative)
    else
      "-"
    end
  end

  def phase_name(:phase_users), do: "Open participation"
  def phase_name(:phase_candidates), do: "Delegate voting"
  def phase_name(:phase_end), do: "Ended"

  def project_user_participation_role(%{:participations => participations} = p, %{:id => user_id}) do
    Enum.find_value(participations, fn(participation) ->
      participation.user_id == user_id && participation.role
    end)
  end
end
