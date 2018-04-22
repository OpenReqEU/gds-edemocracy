defmodule ExVote.Repo.Migrations.RefactorParticipationVotes do
  use Ecto.Migration

  def change do
    alter table("participations") do
      remove :vote_candidate_id
      remove :vote_ticket_id

      add :vote_user_id, references(:users)
      add :vote_candidate_id, references(:tickets)
    end
  end
end
