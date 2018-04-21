defmodule ExVote.Projects do
  import Ecto.Query

  alias ExVote.Repo
  alias ExVote.Phases
  alias ExVote.Projects.{Project, Ticket, Participation}
  alias ExVote.Accounts.User

  def list_projects do
    Project
    |> Repo.all()
    |> Enum.map(&Project.compute_phase/1)
  end

  def get_project(project_id) do
    query = from p in Project,
      where: p.id == ^project_id

    Repo.one(query)
  end

  def create_project(attrs \\ %{}) do
    insertion = %Project{}
    |> Project.changeset_create(attrs)
    |> Repo.insert()

    case insertion do
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
  end

  def add_user(
    %Project{:id => project_id},
    %User{:id => user_id},
    role \\ "user",
    candidate_summary \\ ""
  ) do
    attrs = %{
      project_id: project_id,
      user_id: user_id,
      role: role,
      candidate_summary: candidate_summary
    }

    insertion =
      %Participation{}
      |> Participation.changeset_create(attrs)
      |> Repo.insert()

    case insertion do
      {:ok, _} = ok -> ok
      error -> error
    end
  end

  def add_candidate_vote(%Project{} = project, %User{} = user, %User{:id => candidate_id}) do
    attrs = %{vote_candidate_id: candidate_id}
    participation = get_participation(project, user)

    if participation do
      %{participation | project: project, user: user}
      |> Participation.changeset_add_candidate_vote(attrs)
      |> Repo.update()
    else
      {:error, "No existing participation"}
    end
  end

  def add_ticket_vote(%Project{} = project, %User{} = user, %Ticket{} = ticket) do
    attrs = %{vote_ticket: ticket}
    participation = get_participation(project, user)

    if participation do
      %{participation | project: project, user: user}
      |> Participation.changeset_add_ticket_vote(attrs)
      |> Repo.update()
    else
      {:error, "No existing participation"}
    end
  end

  def get_participation(%Project{:id => project_id}, %User{:id => user_id}) do
    participation_query = from p in Participation,
      left_join: u in assoc(p, :user),
      left_join: c in assoc(p, :vote_candidate),
      left_join: t in assoc(p, :vote_ticket),
      preload: [user: u, vote_candidate: c, vote_ticket: t],
      where: p.project_id == ^project_id and p.user_id == ^user_id

    Repo.one(participation_query)
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
