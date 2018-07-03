defmodule ExVote.Repo.Migrations.AlterTicket do
  use Ecto.Migration

  def change do
    alter table("tickets") do
      add :external_id, :integer
      add :description, :text
    end
  end
end
