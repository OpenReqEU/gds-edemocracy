defmodule ExVote.Participations.CandidateParticipation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects.{Project, Ticket}
  alias ExVote.Accounts.User

  schema "participations" do
    field :role, :string
    field :candidate_summary
    belongs_to :project, Project
    belongs_to :user, User
    belongs_to :vote_candidate, Ticket
  end

  @doc false
  def changeset_create(participation, attrs) do
    participation
    |> cast(attrs, [:role, :candidate_summary, :project_id, :user_id])
    |> validate_required([:role, :candidate_summary, :project_id, :user_id])
    |> validate_role()
    |> unique_constraint(:project_id, name: :index_unique_participations)
    |> assoc_constraint(:project)
    |> assoc_constraint(:user)
  end

  @doc false
  def changeset_update_vote(participation, attrs) do
    participation
    |> cast(attrs, [:role, :vote_candidate_id])
    |> validate_required([:vote_candidate_id])
    |> validate_role()
    |> assoc_constraint(:vote_candidate)
  end

  @doc false
  def changeset_cast(participation, attrs) do
    participation
    |> cast(attrs, [:id, :role, :candidate_summary, :project_id, :user_id, :vote_candidate_id])
  end

  defp validate_role(changeset) do
    validate_change(changeset, :role, fn
      :role, "candidate" -> []
      :role, "user" -> [role: "Role cannot be user for candidate participation"]
      :role, invalid_role -> [role: "Invalid role: #{invalid_role}"]
    end)
  end
end
