defmodule ExVoteWeb.Plugs.ProjectPlugs do
  import Plug.Conn

  alias ExVote.Projects

  def fetch_project(conn, _opts) do
    project =
      if project_id = conn.params["project_id"] do
        Projects.get_project(project_id)
      end

    assign(conn, :project, project)
  end

end
