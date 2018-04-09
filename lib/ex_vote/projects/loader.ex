defmodule ExVote.Projects.Loader do
  use Task

  alias ExVote.Projects

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    Projects.list_projects
    |> Enum.each(&Projects.start_project_server/1)
  end
end
