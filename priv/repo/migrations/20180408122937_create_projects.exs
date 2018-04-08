defmodule ExVote.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :title, :string

      timestamps()
    end

  end
end
