defmodule ExVote.Projects.ProjectServer do
  use GenServer, restart: :transient
  import Logger

  alias ExVote.Projects.Project

  # Client

  def start_link(%Project{:id => project_id} = project) do
    GenServer.start_link(__MODULE__, {:start_project, project}, name: via_tuple(project_id))
  end

   def get(project_id) do
     GenServer.call(via_tuple(project_id), :get)
   end

   def delete(project_id) do
     GenServer.cast(via_tuple(project_id), :delete)
   end

  defp via_tuple(project_id) do
    {:via, Registry, {ExVote.Projects.Registry, project_id}}
  end

  # Server

  def init({:start_project, %Project{} = project}) do
    schedule_phase_change(project)

    {:ok, project}
  end

  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

  def handle_cast(:delete, state) do
    {:stop, :normal, state}
  end

  def handle_info({:next_phase, next_phase}, state) do
    Logger.debug("[#{state.id}] Now entering phase #{next_phase}")
    updated_project = Project.compute_phase(state)
    schedule_phase_change(updated_project)

    {:noreply, updated_project}
  end

  defp schedule_phase_change(project) do
    {next_phase, time_left} = Project.time_to_next_phase(project)

    if next_phase != :no_next_phase do
      Logger.debug("[#{project.id}] Scheduling phase change to #{next_phase} in #{time_left}ms")
      Process.send_after(self(), {:next_phase, next_phase}, time_left)
    end
  end

end
