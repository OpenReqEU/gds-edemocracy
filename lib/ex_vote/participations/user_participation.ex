defmodule ExVote.Participations.UserParticipation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects.Project
  alias ExVote.Accounts.User

  schema "participations" do
    field :role, :string
    belongs_to :project, Project
    belongs_to :user, User
    belongs_to :vote_user, User
  end

  @doc false
  def changeset_create(participation, attrs) do
    participation
    |> cast(attrs, [:role, :project_id, :user_id])
    |> validate_required([:role, :project_id, :user_id])
    |> validate_role()
    |> unique_constraint(:project_id, name: :index_unique_participations)
    |> assoc_constraint(:project)
    |> assoc_constraint(:user)
  end

  @doc false
  def changeset_update_vote(participation, attrs) do
    participation
    |> cast(attrs, [:role, :vote_user_id])
    |> validate_required([:vote_user_id])
    |> validate_role()
    |> assoc_constraint(:vote_user)
  end

  @doc false
  def changeset_cast(participation, attrs) do
    changeset =
      participation
      |> cast(attrs, [:id, :role, :project_id, :user_id, :vote_user_id])

    if Ecto.assoc_loaded?(attrs.user) do
      put_assoc(changeset, :user, attrs.user)
    else
      changeset
    end
  end

  defp validate_role(changeset) do
    validate_change(changeset, :role, fn
      :role, "user" -> []
      :role, "candidate" -> [role: "Role cannot be candidate for user participation"]
      :role, invalid_role -> [role: "Invalid role: #{invalid_role}"]
    end)
  end
end
