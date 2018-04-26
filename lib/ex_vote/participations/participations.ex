defmodule ExVote.Participations do
  import Ecto.Query

  alias ExVote.Repo
  alias ExVote.Participations.{
    Participation,
    UserParticipation,
    CandidateParticipation
  }
  alias ExVote.Projects.Project

  def get_participations(%Project{:id => project_id}, role_filter \\ nil) do
    query = from p in Participation,
      where: p.project_id == ^project_id,
      left_join: u in assoc(p, :user),
      preload: [user: u]

    query = if role_filter do
      from p in query,
        where: p.role == ^role_filter
    else
      query
    end

    Repo.all(query)
    |> Enum.map(&cast_participation/1)
  end

  def get_participation(%{:id => project_id}, %{:id => user_id}, role_filter \\ nil) do
    query = from p in Participation,
      where: p.project_id == ^project_id and p.user_id == ^user_id

    query = if role_filter do
      from p in query,
        where: p.role == ^role_filter
    else
      query
    end

    case Repo.one(query) do
      %Participation{} = participation -> cast_participation(participation)
      nil -> nil
    end
  end

  def cast_participation(%{:role => "user"} = participation) do
    %UserParticipation{}
    |> UserParticipation.changeset_cast(Map.from_struct(participation))
    |> Ecto.Changeset.apply_changes()
  end

  def cast_participation(%Participation{:role => "candidate"} = participation) do
    %CandidateParticipation{}
    |> CandidateParticipation.changeset_cast(Map.from_struct(participation))
    |> Ecto.Changeset.apply_changes()
  end

  def create_participation(%{"role" => "user"} = attrs) do
    %UserParticipation{}
    |> UserParticipation.changeset_create(attrs)
    |> Repo.insert()
  end

  def create_participation(%{"role" => "candidate"} = attrs) do
    %CandidateParticipation{}
    |> CandidateParticipation.changeset_create(attrs)
    |> Repo.insert()
  end

  def update_vote(%UserParticipation{} = participation, attrs) do
    participation
    |> UserParticipation.changeset_update_vote(attrs)
    |> Repo.update()
  end

  def update_vote(%CandidateParticipation{} = participation, attrs) do
    participation
    |> CandidateParticipation.changeset_update_vote(attrs)
    |> Repo.update()
  end
end
