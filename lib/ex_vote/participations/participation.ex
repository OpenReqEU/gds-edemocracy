defmodule ExVote.Participations.Participation do
  use Ecto.Schema

  alias ExVote.Projects.{Project, Ticket}
  alias ExVote.Accounts.User

  schema "participations" do
    field :role, :string
    field :candidate_summary, :string
    belongs_to :project, Project
    belongs_to :user, User
    belongs_to :vote_user, User
    belongs_to :vote_candidate, Ticket
  end
end
