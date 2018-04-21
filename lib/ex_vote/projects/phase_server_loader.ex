defmodule ExVote.Projects.PhaseServerLoader do
  use Task

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    ExVote.Projects.list_projects
    # |> Enum.each(&Projects.start_project_server/1)
    |> Enum.each(&ExVote.Phases.start_phase_server/1)
  end
end
