defmodule ExVote.Phases do
  require Logger

  alias ExVote.Phases.ProjectPhaseServer
  alias ExVote.Projects.Project

  def start_phase_server(%Project{:id => project_id} = project) do
    Logger.debug("Starting phase server for project(id: #{project_id})")
    DynamicSupervisor.start_child(ExVote.Phases.ProjectPhasesSupervisor, {ProjectPhaseServer, project})
  end
end
