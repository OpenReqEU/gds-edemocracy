defmodule ExVote.Repo.Migrations.RemoveParticipationCandidateVote do
  use Ecto.Migration

  def change do
    alter table("participations") do
      remove :vote_candidate_id
    end
  end
end
