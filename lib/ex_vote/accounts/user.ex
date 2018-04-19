defmodule ExVote.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset


  schema "users" do
    field :name, :string
    has_many :participations, ExVote.Projects.Participation

    timestamps()
  end

  @doc false
  def changeset_create(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
