defmodule ExVote.Repo.Migrations.AddParticipationVotes do
  use Ecto.Migration

  def change do
    alter table("participations") do
      add :vote_candidate_id, references(:users)
      add :vote_ticket_id, references(:tickets)
    end
  end
end
