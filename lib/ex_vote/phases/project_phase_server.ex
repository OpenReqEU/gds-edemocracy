defmodule ExVote.Phases.ProjectPhaseServer do
  use GenServer, restart: :transient

  import Ecto.Query
  import Logger

  alias ExVote.Repo
  alias ExVote.Projects.Project

  # Client

  def start_link(%Project{:id => project_id} = project) do
    GenServer.start_link(__MODULE__, {:start_phase_struct, project}, name: via_tuple(project_id))
  end

  def start_link(project_id) do
    GenServer.start_link(__MODULE__, {:start_phase_id, project_id}, name: via_tuple(project_id))
  end

  defp via_tuple(project_id) do
    {:via, Registry, {ExVote.Phases.ProjectPhasesRegistry, project_id}}
  end

  # Server

  def init({:start_phase_struct, project}) do
    schedule_phase_change(project)

    {:ok, project}
  end

  def init({:start_phase_id, project_id}) do
    query = from p in Project,
      where: p.id == ^project_id,
      select: struct(p, [:id, :phase_candidates, :phase_end])

    case Repo.one(query) do
      %Project{} = project ->
        project = project
        |> Project.compute_phase()
        |> schedule_phase_change()

        {:ok, project}
      nil ->
        {:stop, "No project found for id #{project_id}"}
    end
  end

  def handle_info({:next_phase, next_phase}, state) do
    Logger.debug("[#{state.id}] Now entering phase #{next_phase}")

    updated_project = state
    |> Project.compute_phase()
    |> schedule_phase_change()

    {:noreply, updated_project}
  end

  defp schedule_phase_change(project) do
    {next_phase, time_left} = Project.time_to_next_phase(project)

    if next_phase != :no_next_phase do
      Logger.debug("[#{project.id}] Scheduling phase change to #{next_phase} in #{time_left}ms")
      Process.send_after(self(), {:next_phase, next_phase}, time_left)
    end

    project
  end

end
