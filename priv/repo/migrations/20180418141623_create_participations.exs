defmodule ExVote.Repo.Migrations.CreateParticipations do
  use Ecto.Migration

  def change do
    create table(:participations) do
      add :project_id, references(:projects)
      add :user_id, references(:users)
      add :role, :string
    end

    create unique_index(:participations, [:project_id, :user_id], name: :index_unique_participations)
  end
end
