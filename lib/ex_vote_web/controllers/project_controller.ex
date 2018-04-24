defmodule ExVoteWeb.ProjectController do
  use ExVoteWeb, :controller

  alias ExVote.Projects

  def index(conn, _params) do
    projects = Projects.list_projects()

    conn
    |> assign(:projects, projects)
    |> render("index.html")
  end

  def view(conn, %{"id" => project_id}) do
    project = Projects.get_project(project_id, [:participations, :tickets])

    conn
    |> assign(:project, project)
    |> render("view.html")
  end
end
