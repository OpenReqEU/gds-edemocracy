defmodule ExVote.Projects.Project do
  use Ecto.Schema

  import Ecto.Changeset
  import Logger
  import NaiveDateTime

  alias ExVote.Participations.Participation
  alias ExVote.Projects.{Project, Ticket}

  schema "projects" do
    field :title, :string
    field :phase_candidates, :naive_datetime
    field :phase_end, :naive_datetime
    field :current_phase, :string, virtual: true
    has_many :tickets, Ticket
    has_many :participations, Participation

    timestamps()
  end

  @allowed_attrs ~w(title phase_candidates phase_end)a
  @required_attrs ~w(title phase_candidates phase_end)a

  @doc false
  def changeset_create(project, attrs) do
    project
    |> cast(attrs, @allowed_attrs)
    |> validate_required(@required_attrs)
    |> cast_assoc(:tickets, with: &Ticket.changeset_create/2)
  end

  def compute_phase(%Project{} = project, now \\ NaiveDateTime.utc_now()) do
    %{:phase_candidates => phase_candidates, :phase_end => phase_end} = project

    current_phase = case compare(now, phase_candidates) do
                      :lt -> :phase_users
                      _ -> case compare(now, phase_end) do
                             :lt -> :phase_candidates
                             _ -> :phase_end
                           end
                    end

    Map.put(project, :current_phase, current_phase)
  end

  def time_to_next_phase(%Project{:current_phase => :phase_end}), do: {:no_next_phase, nil}

  def time_to_next_phase(%Project{:current_phase => :phase_candidates} = project) do
    %{:phase_end => phase_end} = project
    time_left = diff(phase_end, utc_now(), :milliseconds)

    {:phase_end, time_left}
  end

  def time_to_next_phase(%Project{:current_phase => :phase_users} = project) do
    %{:phase_candidates => phase_candidates} = project
    time_left = diff(phase_candidates, utc_now(), :milliseconds)

    {:phase_candidates, time_left}
  end

  def next_phase_at(%Project{:current_phase => :phase_end}), do: nil
  def next_phase_at(%Project{:current_phase => :phase_candidates, :phase_end => phase_end}), do: phase_end
  def next_phase_at(%Project{:current_phase => :phase_users, :phase_candidates => phase_candidates}), do: phase_candidates

end
