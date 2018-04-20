defmodule ExVote.Projects.Participation do
  use Ecto.Schema

  import Ecto.Changeset

  alias ExVote.Projects.{Project, Ticket}
  alias ExVote.Accounts.User

  schema "participations" do
    field :role, :string
    field :candidate_summary, :string
    belongs_to :vote_candidate, User
    belongs_to :vote_ticket, Ticket
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
    |> validate_role()
    |> validate_candidate()
    |> unique_constraint(:project_id, name: :index_unique_participations)
    |> assoc_constraint(:project)
    |> assoc_constraint(:user)
  end

  @doc false
  def changeset_add_vote(participation, attrs) do
    participation
    |> cast(attrs, [:vote_candidate_id, :vote_ticket_id])
    |> put_assoc(:vote_candidate, Map.get(participation, :vote_candidate, nil))
    |> put_assoc(:vote_ticket, Map.get(participation, :vote_ticket, nil))
    |> validate_role()
    |> validate_vote()
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

  defp validate_vote(changeset) do
    role = get_field(changeset, :role, nil)
    vote_candidate_id = get_field(changeset, :vote_candidate_id, nil)
    vote_ticket_id = get_field(changeset, :vote_ticket_id, nil)

    case role do
      "user" ->
          if vote_ticket_id do
            add_error(changeset, :vote_ticket, "Permission denied for role")
          else
            assoc_constraint(changeset, :vote_candidate)
          end
      "candidate" ->
          if vote_candidate_id do
            add_error(changeset, :vote_candidate, "Permission denied for role")
          else
            assoc_constraint(changeset, :vote_ticket)
          end
    end
  end

  # defp validate_vote_candidate(changeset) do
  #   role = get_field(changeset, :role, nil)
  #   candidate_id = get_change(changeset, :vote_candidate_id)

  #   if candidate_id do
  #     if role != "user" do
  #       add_error(changeset, :vote_candidate, "Invalid vote type for role")
  #     else
  #       changeset
  #       |> assoc_constraint(:vote_candidate)
  #     end
  #   else
  #     changeset
  #   end
  # end

  # defp validate_vote_ticket(changeset) do
  #   role = get_field(changeset, :role, nil)
  #   ticket_id = get_change(changeset, :vote_ticket_id)

  #   if ticket_id do
  #     if role != "candidate" do
  #       add_error(changeset, :vote_ticket, "Invalid vote type for role")
  #     else
  #       changeset
  #       |> assoc_constraint(:vote_ticket)
  #     end
  #   else
  #     changeset
  #   end
  # end
end
