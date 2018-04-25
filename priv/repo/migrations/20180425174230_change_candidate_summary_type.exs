defmodule ExVote.Repo.Migrations.ChangeCandidateSummaryType do
  use Ecto.Migration

  def change do
    alter table("participations") do
      modify :candidate_summary, :text
    end
  end
end
