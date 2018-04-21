defmodule ExVote.Projects do
  import Ecto.Query
  import Logger

  alias ExVote.Repo
  alias ExVote.Projects.{Project, ProjectServer, Ticket, Participation}
  alias ExVote.Accounts.User

  def list_projects do
    # Fetch all projects with associated tickets and participations
    query = from project in Project,
      left_join: tickets in assoc(project, :tickets),
      left_join: participations in assoc(project, :participations),
      left_join: user in assoc(participations, :user),
      preload: [tickets: tickets, participations: {participations, user: user}],
      order_by: [desc: project.inserted_at]

    query
    |> Repo.all()
    |> Enum.map(&Project.compute_phase/1)
  end

  def get_project(project_id) do
    if project_server_alive?(project_id) do
      {:ok, ProjectServer.get(project_id)}
    else
      Logger.warn("Failed to lookup project with id #{project_id}")
      {:error, "Project not found"}
    end
  end

  def create_project(attrs \\ %{}) do
    insertion =
      %Project{}
      |> Project.changeset_create(attrs)
      |> Repo.insert()

      with {:ok, project} <- insertion,
            project_with_associations <- preload_associations(project),
            project_with_phase <- Project.compute_phase(project_with_associations),
            {:ok, _} <- start_project_server(project_with_phase) do
        {:ok, project_with_phase}
      else
        error -> error
      end
  end

  def delete_project(project_id) do
    deleted = Repo.delete(%Project{id: project_id})
    ProjectServer.delete(project_id)

    deleted
  end

  def add_user(
    %Project{:id => project_id},
    %User{:id => user_id} = user,
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
      {:ok, participation} ->
        participation = %{participation | user: user}
        {:ok, ProjectServer.add_participation(project_id, participation)}
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

  def start_project_server(%Project{} = project) do
    Logger.debug("Starting project server for id #{project.id}")
    DynamicSupervisor.start_child(ExVote.Projects.Supervisor, {ProjectServer, project})
  end

  def project_server_alive?(project_id) do
    match?([{_, _}], Registry.lookup(ExVote.Projects.Registry, project_id))
  end

  defp preload_associations(project) do
    participations = from participation in Participation,
      left_join: user in assoc(participation, :user),
      preload: [user: user],
      order_by: [desc: user.inserted_at]

    tickets = from ticket in Ticket,
      order_by: [desc: ticket.inserted_at]

    project |> Repo.preload([tickets: tickets, participations: {participations, [:user]}])
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
