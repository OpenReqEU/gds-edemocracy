defmodule ExVote.Participations.CandidateParticipation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects
  alias ExVote.Accounts
  alias ExVote.Participations

  schema "participations" do
    field :role, :string
    field :candidate_summary
    belongs_to :project, Projects.Project
    belongs_to :user, Accounts.User
    has_many :votes_candidate, Participations.ParticipationTicket, foreign_key: :participation_id
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
  def changeset_cast(participation, attrs) do
    changeset =
      participation
      |> cast(attrs, [:id, :role, :candidate_summary, :project_id, :user_id])

    if Ecto.assoc_loaded?(attrs.user) do
      put_assoc(changeset, :user, attrs.user)
    else
      changeset
    end
  end

  defp validate_role(changeset) do
    validate_change(changeset, :role, fn
      :role, "candidate" -> []
      :role, "user" -> [role: "Role cannot be user for candidate participation"]
      :role, invalid_role -> [role: "Invalid role: #{invalid_role}"]
    end)
  end
end
