defmodule ExVote.Projects do

  import Ecto.Query

  alias ExVote.Repo
  alias ExVote.Phases
  alias ExVote.Projects.{Project, Ticket}
  alias ExVote.Accounts.User
  alias ExVote.Participations

  def list_projects do
    Project
    |> Repo.all()
    |> Enum.map(&Project.compute_phase/1)
  end

  def get_project(project_id, assocs \\ []) when is_list(assocs) do
    query = from p in Project,
      where: p.id == ^project_id

    query_with_assocs = Enum.reduce(assocs, query, fn(association, query) ->
      from p in query,
        left_join: a in assoc(p, ^association),
        preload: [{^association, a}]
    end)

    result =
      Repo.one(query_with_assocs)
      |> Project.compute_phase()

    if result && is_list(Map.get(result, :participations)) do
      casted_participations = Enum.map(result.participations, &Participations.cast_participation/1)
      %{result | participations: casted_participations}
    else
      result
    end
  end

  def create_project(attrs \\ %{}) do
    result = %Project{}
    |> Project.changeset_create(attrs)
    |> Repo.insert()

    case result do
      {:ok, project} ->
        project = Project.compute_phase(project)
        Phases.start_phase_server(project)

        {:ok, project}
      error ->
        error
    end
  end

  def delete_project(project_id) do
    Repo.delete(%Project{id: project_id})
    # TODO: shut down the phase server
  end

  def add_user(%Project{:id => project_id}, %User{:id => user_id}) do
    attrs = %{
      "project_id": project_id,
      "user_id": user_id,
      "role": "user",
    }

    Participations.create_participation(attrs)
  end

  def add_user(attrs \\ %{}) do
    attrs
    |> Map.put("role", "user")
    |> Participations.create_participation()
  end

  def add_candidate(%Project{:id => project_id}, %User{:id => user_id}, candidate_summary) do
    attrs = %{
      "project_id": project_id,
      "user_id": user_id,
      "role": "candidate",
      "candidate_summary": candidate_summary
    }

    Participations.create_participation(attrs)
  end

  def add_candidate(attrs \\ %{}) do
    attrs
    |> Map.put("role", "candidate")
    |> Participations.create_participation()
  end

  def add_user_vote(%Project{} = project, %User{} = user, %User{id: vote_user_id}) do
    Participations.get_participation(project, user)
    |> Participations.update_vote(%{"vote_user_id": vote_user_id})
  end

  def add_user_vote(attrs \\ %{}) do
    # TODO: handle error cases
    Participations.get_participation(%{id: Map.get(attrs, "project_id")}, %{id: Map.get(attrs, "user_id")})
    |> Participations.update_vote(attrs)
  end

  def add_candidate_vote(%Project{} = project, %User{} = user, %Ticket{id: ticket_id}) do
    %{:id => participation_id} = Participations.get_participation(project, user)

    attrs = %{
      "participation_id": participation_id,
      "ticket_id": ticket_id
    }

    Participations.add_candidate_vote(attrs)
  end

  def add_candidate_vote(attrs \\ %{}) do
    # TODO: handle error cases
    # Participations.get_participation(%{id: Map.get(attrs, "project_id")}, %{id: Map.get(attrs, "user_id")})
    attrs
    |> Participations.add_candidate_vote()
  end

  def delete_candidate_vote(participation_ticket_id) do
    Participations.delete_candidate_vote(participation_ticket_id)
  end

end
