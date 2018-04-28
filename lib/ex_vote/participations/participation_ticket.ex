defmodule ExVote.Participations.ParticipationTicket do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Participations
  alias ExVote.Projects

  schema "participations_tickets" do
    belongs_to :participation, Participations.Participation
    belongs_to :ticket, Projects.Ticket
  end

  @doc false
  def changeset_create(participation_ticket, attrs) do
    participation_ticket
    |> cast(attrs, [:participation_id, :ticket_id])
    |> validate_required([:participation_id, :ticket_id])
    |> foreign_key_constraint(:participation_id)
    |> foreign_key_constraint(:ticket_id)
    |> unique_constraint(:participation_id, name: :index_unique_participations_tickets)
  end
end
