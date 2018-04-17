defmodule ExVote.Repo.Migrations.AddProjectPhases do
  use Ecto.Migration

  def change do
    alter table("projects") do
      add :phase_candidates, :naive_datetime
      add :phase_end, :naive_datetime
    end
  end
end
