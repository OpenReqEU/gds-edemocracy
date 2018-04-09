defmodule ExVote.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :title, :string
    has_many :tickets, ExVote.Tickets.Ticket

    timestamps()
  end

  @doc false
  def changeset_create(project, attrs) do
    project
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> cast_assoc(:tickets, with: &ExVote.Tickets.Ticket.changeset_create/2)
  end
end
