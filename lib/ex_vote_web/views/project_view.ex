defmodule ExVoteWeb.ProjectView do
  use ExVoteWeb, :view

  alias ExVote.Participations

  # Overridden render functions

  def render("components/info_box.html", assigns) do

    rendered =
      case assigns.project.current_phase do
        :phase_users ->
          render("components/info_box/phase_users.html", assigns)
        :phase_candidates ->
          render("components/info_box/phase_candidates.html", assigns)
        :phase_end ->
          render("components/info_box/phase_end.html", assigns)
      end

    assigns = Map.put(assigns, :inner_template, rendered)

    render("components/_info_box.html", assigns)
  end

  def render("components/participation_box.html", assigns) do

    rendered =
      case assigns.project.current_phase do
        :phase_users ->
          render("components/participation_box/phase_users.html", assigns)
        :phase_candidates ->
          render("components/participation_box/phase_candidates.html", assigns)
        :phase_end ->
          render("components/participation_box/phase_end.html", assigns)
      end

    assigns = Map.put(assigns, :inner_template, rendered)

    render("components/_participation_box.html", assigns)
  end

  # Template helpers

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

  def changeset_create_user do
    Participations.UserParticipation.changeset_create(%Participations.UserParticipation{}, %{})
  end

  def changeset_create_candidate do
    Participations.CandidateParticipation.changeset_create(%Participations.CandidateParticipation{}, %{})
  end

  def changeset_add_user_vote do
    Participations.UserParticipation.changeset_update_vote(%Participations.UserParticipation{}, %{})
  end

  def project_user_participation_role(%{:participations => participations}, %{:id => user_id}) do
    Enum.find_value(participations, fn(participation) ->
      participation.user_id == user_id && participation.role
    end)
  end

  def get_candidates(project) do
    ExVote.Participations.get_participations(project, "candidate")
  end

  def project_user_has_voted?(%{:participations => participations}, %{:id => user_id}) do
    Enum.any?(participations, fn
      %Participations.UserParticipation{} = participation ->
        participation.user_id == user_id && participation.vote_user_id
      %Participations.CandidateParticipation{} = participation ->
        participation.user_id == user_id && participation.vote_candidate_id
    end)
  end

end
