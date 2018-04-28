defmodule ExVote.Participations.Participation do
  use Ecto.Schema

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
end
