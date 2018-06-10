defmodule ExVote.Projects.Ticket do
  use Ecto.Schema
  import Ecto.Changeset


  schema "tickets" do
    field :title, :string
    field :url, :string
    belongs_to :project, ExVote.Projects.Project

    timestamps()
  end

  @doc false
  def changeset_create(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :url])
    |> validate_required([:title])
  end
end
