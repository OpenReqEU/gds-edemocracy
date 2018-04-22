defmodule ExVoteWeb.ProjectController do
  use ExVoteWeb, :controller

  def index(conn, _params) do
    projects = ExVote.Projects.list_projects()

    conn
    |> assign(:projects, projects)
    |> render("index.html")
  end
end
