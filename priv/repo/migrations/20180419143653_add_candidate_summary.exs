defmodule ExVote.Repo.Migrations.AddCandidateSummary do
  use Ecto.Migration

  def change do
    alter table("participations") do
      add :candidate_summary, :string
    end
  end
end
