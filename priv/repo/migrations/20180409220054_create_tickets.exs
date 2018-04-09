defmodule ExVote.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :title, :string
      add :url, :string
      add :project_id, references(:projects, on_delete: :delete_all)

      timestamps()
    end

    create index(:tickets, [:project_id])
  end
end
