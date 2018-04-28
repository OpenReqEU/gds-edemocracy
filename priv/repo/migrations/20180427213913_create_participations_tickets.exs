defmodule ExVote.Repo.Migrations.CreateParticipationsTickets do
  use Ecto.Migration

  def change do
    create table(:participations_tickets) do
      add :participation_id, references(:participations, on_delete: :delete_all)
      add :ticket_id, references(:tickets, on_delete: :delete_all)
    end

    create unique_index(:participations_tickets, [:participation_id, :ticket_id], name: :index_unique_participations_tickets)
  end
end
