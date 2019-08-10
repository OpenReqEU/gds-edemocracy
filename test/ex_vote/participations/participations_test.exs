defmodule ExVote.ParticipationsTest do
  use ExVote.DataCase

  alias ExVote.Participations
  alias ExVote.Participations.CandidateParticipation
  alias ExVote.Participations.UserParticipation
  alias ExVote.Participations.Participation
  alias ExVote.Participations.ParticipationTicket
  alias ExVote.Accounts.User
  alias ExVote.Projects.Project
  alias ExVote.Projects.Ticket

  describe "Participation as candidate" do
    setup  do

      {:ok, user1} =  ExVote.Repo.insert %User{name: "test user1"}
      {:ok, user2} =  ExVote.Repo.insert %User{name: "test user2"}

      {:ok, project} =  ExVote.Repo.insert %Project{title: "test project"}
      {:ok, ticket} =  ExVote.Repo.insert %Ticket{title: "test ticket", url: "tet url", description: "some description", project: project}

      {:ok, participation1} = ExVote.Repo.insert %CandidateParticipation{role: "user", candidate_summary: "vote me", project: project, user: user1}
      {:ok, participation2} = ExVote.Repo.insert %CandidateParticipation{role: "candidate", candidate_summary: "vote me", project: project, user: user2}

      [p1: participation1, p2: participation2, tid: ticket.id]
    end

    test "updating votes with empty array removes all vote for the current user", context do
      votes = %{:votes => [context[:tid]]}
      Participations.update_votes(context[:p1], votes)
      Participations.update_votes(context[:p2], votes)

      empty_votes = %{:votes => []}
      Participations.update_votes(context[:p1], empty_votes)

      votes_p1 = Participations.get_votes(context[:p1])
      votes_p2 = Participations.get_votes(context[:p2])

      assert(length(votes_p1) == 0)
      assert(length(votes_p2) == 1)
    end
  end
end
