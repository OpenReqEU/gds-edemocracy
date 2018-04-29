defmodule ExVote.Participations.Participation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects
  alias ExVote.Accounts
  alias ExVote.Participations

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
  end
end
