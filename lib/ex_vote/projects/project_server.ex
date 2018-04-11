defmodule ExVote.Projects.ProjectServer do
  use GenServer, restart: :transient

  alias ExVote.Projects.Project

  # Client

  # def start_link(project_id) when is_integer(project_id) do
  #   GenServer.start_link(__MODULE__, {:start_id, project_id}, name: via_tuple(project_id))
  # end

  def start_link(%Project{:id => project_id} = project) do
    GenServer.start_link(__MODULE__, {:start_project, project}, name: via_tuple(project_id))
  end

   def get(project_id) do
     GenServer.call(via_tuple(project_id), :get)
   end

   def delete(project_id) do
     GenServer.cast(via_tuple(project_id), :delete)
   end

  # def set(%Project{} = project, %Project{} = new_project) do
  #   GenServer.call(via_tuple(project), {:set, new_project})
  # end

  defp via_tuple(project_id) do
    {:via, Registry, {ExVote.Projects.Registry, project_id}}
  end

  # Server

  # def init({:start_id, project_id}) do
  #   project =
  #     Project
  #     |> Repo.get(project_id)

  #   case project do
  #     nil -> {:stop, "Could not load project"}
  #     %Project{} -> {:ok, project}
  #   end
  # end

  def init({:start_project, %Project{} = project}) do
    {:ok, project}
  end

  def handle_call(:get, _, state) do
    {:reply, state, state}
  end

  def handle_cast(:delete, state) do
    {:stop, :normal, state}
  end

  # def handle_call({:set, project}, _, _) do
  #   {:reply, :ok, project}
  # end

end
