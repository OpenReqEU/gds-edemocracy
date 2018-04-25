defmodule ExVote.Projects do
  import Ecto.Query

  alias ExVote.Repo
  alias ExVote.Phases
  alias ExVote.Projects.{Project, Ticket}
  alias ExVote.Accounts.User
  alias ExVote.Participations
  alias ExVote.Participations.{UserParticipation, CandidateParticipation}

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

    if is_list(Map.get(result, :participations)) do
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
      project_id: project_id,
      user_id: user_id,
      role: "user",
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
      project_id: project_id,
      user_id: user_id,
      role: "candidate",
      candidate_summary: candidate_summary
    }

    Participations.create_participation(attrs)
  end

  def add_candidate(attrs \\ %{}) do
    attrs
    |> Map.put("role", "candidate")
    |> Participations.create_participation()
  end

  # def add_user_vote(%Project{} = project, %User{} = user, %User{} = candidate) do
  #   # TODO: expose some kind of function to fetch multiple records at once
  #   user_participation = Participations.get_participation(project, user, "user")
  #   candidate_participation = Participations.get_participation(project, candidate, "candidate")

  #   handle_user_vote(user_participation, candidate_participation)
  # end

  def add_user_vote(attrs \\ %{}) do
    # TODO: handle error cases (candidate not in project, see add_user_vote/2)
    Participations.get_participation(%{id: Map.get(attrs, "project_id")}, %{id: Map.get(attrs, "user_id")})
    |> Participations.update_vote(attrs)
  end

  # defp handle_user_vote(nil, _), do: {:error, "Invalid user"}
  # defp handle_user_vote(_, nil), do: {:error, "Invalid vote"}

  # defp handle_user_vote(
  #   %UserParticipation{} = user_participation,
  #   %CandidateParticipation{:user_id => candidate_id}
  # ) do
  #   vote = %{
  #     vote_user_id: candidate_id
  #   }

  #   Participations.update_vote(user_participation, vote)
  # end

  def add_candidate_vote(%Project{} = project, %User{} = user, %Ticket{} = ticket) do
    candidate_participation = Participations.get_participation(project, user, "candidate")

    valid_ticket? = project
    |> Repo.preload(:tickets)
    |> Map.get(:tickets)
    |> Enum.any?(fn(%Ticket{:id => id}) -> id == ticket.id end)

    handle_candidate_vote(candidate_participation, ticket, valid_ticket?)
  end

  def add_candidate_vote(attrs \\ %{}) do
    # TODO: handle error cases (candidate not in project, see add_candidate_vote/2)
    Participations.get_participation(%{id: Map.get(attrs, "project_id")}, %{id: Map.get(attrs, "user_id")})
    |> Participations.update_vote(attrs)
  end

  defp handle_candidate_vote(nil, _, _), do: {:error, "Invalid user"}
  defp handle_candidate_vote(_, nil, _), do: {:error, "Invalid vote"}
  defp handle_candidate_vote(_, _, false), do: {:error, "Invalid vote"}

  defp handle_candidate_vote(
    %CandidateParticipation{} = candidate,
    %Ticket{:id => ticket_id},
    true
  ) do
    vote = %{
      vote_candidate_id: ticket_id
    }

    Participations.update_vote(candidate, vote)
  end

  # @moduledoc """
  # The Projects context.
  # """

  # import Ecto.Query, warn: false
  # alias ExVote.Repo

  # alias ExVote.Projects.Project

  # @doc """
  # Returns the list of projects.

  # ## Examples

  #     iex> list_projects()
  #     [%Project{}, ...]

  # """
  # def list_projects do
  #   Repo.all(Project)
  # end

  # @doc """
  # Gets a single project.

  # Raises `Ecto.NoResultsError` if the Project does not exist.

  # ## Examples

  #     iex> get_project!(123)
  #     %Project{}

  #     iex> get_project!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_project!(id), do: Repo.get!(Project, id)

  # @doc """
  # Creates a project.

  # ## Examples

  #     iex> create_project(%{field: value})
  #     {:ok, %Project{}}

  #     iex> create_project(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def create_project(attrs \\ %{}) do
  #   %Project{}
  #   |> Project.changeset(attrs)
  #   |> Repo.insert()
  # end

  # @doc """
  # Updates a project.

  # ## Examples

  #     iex> update_project(project, %{field: new_value})
  #     {:ok, %Project{}}

  #     iex> update_project(project, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_project(%Project{} = project, attrs) do
  #   project
  #   |> Project.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a Project.

  # ## Examples

  #     iex> delete_project(project)
  #     {:ok, %Project{}}

  #     iex> delete_project(project)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_project(%Project{} = project) do
  #   Repo.delete(project)
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking project changes.

  # ## Examples

  #     iex> change_project(project)
  #     %Ecto.Changeset{source: %Project{}}

  # """
  # def change_project(%Project{} = project) do
  #   Project.changeset(project, %{})
  # end
end
