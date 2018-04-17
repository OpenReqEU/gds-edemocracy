defmodule ExVote.Projects do
  import Ecto.Query
  import Logger

  alias ExVote.Repo
  alias ExVote.Projects.{Project, ProjectServer}

  def list_projects do
    # Fetch all projects with associated tickets
    query = from p in Project,
      left_join: t in assoc(p, :tickets),
      preload: [tickets: t],
      order_by: [desc: p.inserted_at]

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
    project =
      %Project{}
      |> Project.changeset_create(attrs)
      |> Repo.insert()

    with {:ok, %{:id => id} = project} <- project,
         project_with_phase <- Project.compute_phase(project),
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

  def start_project_server(%Project{} = project) do
    Logger.debug("Starting project server for id #{project.id}")
    DynamicSupervisor.start_child(ExVote.Projects.Supervisor, {ProjectServer, project})
  end

  def project_server_alive?(project_id) do
    match?([{_, _}], Registry.lookup(ExVote.Projects.Registry, project_id))
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
