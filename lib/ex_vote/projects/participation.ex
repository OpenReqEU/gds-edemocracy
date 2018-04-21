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

  # @doc false
  # def changeset_add_vote(participation, attrs) do
  #   participation
  #   |> cast(attrs, [:vote_candidate_id, :vote_ticket_id])
  #   |> put_assoc(:vote_candidate, Map.get(participation, :vote_candidate, nil))
  #   |> put_assoc(:vote_ticket, Map.get(participation, :vote_ticket, nil))
  #   |> validate_role()
  #   |> validate_vote()
  # end

  @doc false
  def changeset_add_candidate_vote(participation, attrs) do
    participation
    |> cast(attrs, [:vote_candidate_id])
    |> validate_role()
    |> validate_candidate_vote_sender()
    |> validate_candidate_vote_receiver()
  end

  def changeset_add_ticket_vote(participation, attrs) do
    participation
    |> cast(attrs, [:vote_ticket_id])
    |> validate_role()
    |> validate_ticket_vote_sender()
    |> validate_ticket_vote_receiver(attrs)
  end

  defp validate_candidate_vote_sender(changeset) do
    role = get_field(changeset, :role, nil)
    if role == "user" do
      has_ticket? = get_field(changeset, :vote_ticket_id, nil) != nil
      if has_ticket? do
        add_error(changeset, :vote_ticket, "Permission denied for role")
      else
        assoc_constraint(changeset, :vote_candidate)
      end
    else
      add_error(changeset, :vote_candidate, "Permission denied for role")
    end
  end

  defp validate_candidate_vote_receiver(changeset) do
    project = get_field(changeset, :project, nil)
    vote_candidate_id = get_field(changeset, :vote_candidate_id, nil)
    valid_candidate? = Enum.any?(project.participations, fn (participation) ->
      participation.user_id == vote_candidate_id && participation.role == "candidate"
    end)

    if valid_candidate? do
      changeset
    else
      add_error(changeset, :vote_candidate_id, "Invalid candidate")
    end
  end

  defp validate_ticket_vote_sender(changeset) do
    role = get_field(changeset, :role, nil)
    if role == "candidate" do
      has_candidate? = get_field(changeset, :vote_candidate_id, nil) != nil
      if has_candidate? do
        add_error(changeset, :vote_candidate, "Permission denied for role")
      else
        assoc_constraint(changeset, :vote_ticket)
      end
    else
      add_error(changeset, :vote_ticket, "Permission denied for role")
    end
  end

  defp validate_ticket_vote_receiver(changeset, attrs) do
    project = get_field(changeset, :project, nil)
    ticket = attrs.vote_ticket
    valid_ticket? = project.id == ticket.project_id

    if valid_ticket? do
      changeset
    else
      add_error(changeset, :vote_ticket_id, "Invalid ticket")
    end
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
