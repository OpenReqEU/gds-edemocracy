defmodule ExVoteWeb.ApiController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  swagger_path :show do
    get "/projects/{id}"
    summary "Get project informations"
    description "Returns a project"
    parameters do
      id :path, :integer, "ID of project to return", required: true
    end
    response 200, "OK", Schema.ref(:project)
  end

  def show(conn, %{"id" => project_id}) do
    project = ExVote.Projects.get_project(project_id, [:tickets])

    conn
    |> assign(:project, project)
    |> render("view.json")
  end

  def swagger_definitions do
    %{
      project: swagger_schema do
        title "Project"
        description "A participation project"
        properties do
          title :string, "Project title", required: true
          phase_candidates_at :string, "Begin of the candidate phase", required: true, format: "date-time"
          phase_end_at :string, "End of the projects lifetime", required: true, format: "date-time"
          current_phase :string, "The current phase of the project", required: true, enum: ["phase_users", "phase_candidates", "phase_end"]
          tickets Schema.ref(:tickets)
        end
      end,
      ticket: swagger_schema do
        title "Ticket"
        description "A single ticket"
        properties do
          title :string, "Ticket title", required: true
          url :string, "URL to the bugtracker", required: true, format: "url"
        end
      end,
      tickets: swagger_schema do
        title "Tickets"
        description "A collection of tickets"
        type :array
        items Schema.ref(:ticket)
      end
    }
  end
end
