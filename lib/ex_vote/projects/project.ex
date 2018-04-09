defmodule ExVote.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset


  schema "projects" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset_create(project, attrs) do
    project
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
