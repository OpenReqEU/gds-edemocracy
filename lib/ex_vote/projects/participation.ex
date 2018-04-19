defmodule ExVote.Projects.Participation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects.Project
  alias ExVote.Accounts.User

  schema "participations" do
    field :role, :string
    field :candidate_summary, :string
    belongs_to :project, Project
    belongs_to :user, User
  end

  @allowed_attrs ~w(role candidate_summary project_id user_id)a
  @required_attrs ~w(role project_id user_id)a

  @doc false
  def changeset_create(participation, attrs) do
    participation
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:project_id, name: :index_unique_participations)
    |> validate_role()
    |> validate_candidate()
  end

  defp validate_role(changeset) do
    validate_change(changeset, :role, fn
      :role, "user" -> []
      :role, "candidate" -> []
      :role, _ -> [role: "invalid role"]
    end)
  end

  defp validate_candidate(changeset) do
    if get_change(changeset, :role) == "candidate" do
      validate_required(changeset, :candidate_summary)
    else
      changeset
    end
  end
end
