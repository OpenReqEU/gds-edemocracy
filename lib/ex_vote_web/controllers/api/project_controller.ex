defmodule ExVoteWeb.Api.ProjectController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  import ExVoteWeb.Plugs.ProjectPlugs

  alias ExVote.Projects
  alias ExVote.Repo

  plug :fetch_project

  swagger_path :index do
    summary "Retrieve a list of all projects"
    tag "Projects"
    security []
    produces "application/json"
    response 200, "OK", Schema.ref(:project_list)
  end

  def index(conn, _params) do
    conn
    |> assign(:projects, Projects.list_projects())
    |> render("index.json")
  end

  swagger_path :show do
    summary "Retrieve a project"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      project_id :path, :integer, "ID of project to return", required: true
    end
    response 200, "OK", Schema.ref(:project)
    response 404, "Not found"
  end

  def show(conn, _params) do
    project =
      conn.assigns[:project]
      |> Repo.preload([:tickets])

    if project do
      conn
      |> assign(:project, project)
      |> render("show.json")
    else
      conn
      |> send_resp(404, "")
    end
  end

  swagger_path :create do
    summary "Create a project"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      body :body, Schema.ref(:project), "The project", required: true
    end
    response 200, "OK", Schema.ref(:project)
    response 400, "Error"
  end

  def create(conn, params) do
    case Projects.create_project(params) do
      {:ok, project} ->
        conn
        |> assign(:project, project)
        |> render("show.json")
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(400)
        |> render("error.json")
    end
  end

  swagger_path :list_tickets do
    summary "Retrieve a list of all tickets"
    tag "Projects"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:ticket_list)
    response 400, "Error"
  end

  def list_tickets(conn, _params) do
    tickets =
      conn.assigns[:project]
      |> Repo.preload([:tickets])
      |> Map.get(:tickets)

    conn
    |> assign(:tickets, tickets)
    |> render("tickets.json")
  end

  def swagger_definitions do
    %{
      project: swagger_schema do
        title "Project"
        description "A participation project"
        properties do
          id :number, "Project id (readonly)"
          title :string, "Project title", required: true
          phase_candidates :string, "Begin of the candidate phase", required: true, format: "date-time"
          phase_end :string, "End of the projects lifetime", required: true, format: "date-time"
          tickets Schema.ref(:ticket_list)
        end
      end,
      short_project: swagger_schema do
        title "Short project"
        description "A short overview of a project"
        properties do
          id :number, "Project id (readonly)"
          title :string, "Project title", required: true
          current_phase ref(:phase), "Current Phase", required: true
        end
      end,
      project_list: swagger_schema do
        title "Project list"
        description "A collection of projects"
        type :array
        items Schema.ref(:short_project)
      end,
      ticket: swagger_schema do
        title "Ticket"
        description "A single ticket"
        properties do
          id :number, "Ticket id (readonly)"
          title :string, "Ticket title", required: true
          url :string, "URL to the bugtracker", required: true, format: "url"
        end
      end,
      ticket_list: swagger_schema do
        title "Tickets"
        description "A collection of tickets"
        type :array
        items Schema.ref(:ticket)
      end,
      phase: swagger_schema do
        type :string
        title "Phase"
        enum ["phase_users", "phase_candidates", "phase_end"]
      end
    }
  end
end
