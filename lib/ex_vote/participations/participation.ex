defmodule ExVote.Participations.Participation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects
  alias ExVote.Accounts
  alias ExVote.Participations

  @valid_roles ~w(user candidate)

  schema "participations" do
    field :role, :string
    field :candidate_summary, :string
    belongs_to :project, Projects.Project
    belongs_to :user, Accounts.User
    belongs_to :vote_user, Accounts.User
    has_many :votes_candidate, Participations.ParticipationTicket
  end

  @doc false
  def changeset_create(participation, attrs) do
    participation
    |> cast(attrs, [:role, :candidate_summary, :project_id, :user_id, :vote_user_id])
    |> validate_required([:role])
    |> validate_role()
  end

  defp validate_role(changeset) do
    validate_change(changeset, :role, fn :role, role ->
      if Enum.any?(@valid_roles, &(&1 == role)) do
        []
      else
        [role: "unknown role"]
      end
    end)
  end
end
