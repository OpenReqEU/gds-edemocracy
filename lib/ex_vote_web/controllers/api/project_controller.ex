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

  swagger_path :report do
    summary "Generate a report"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      project_id :path, :integer, "ID of project", required: true
    end
    response 200, "OK", Schema.ref(:report)
    response 404, "Not found"
  end

  def report(conn, _params) do
    with project when not is_nil(project) <- conn.assigns[:project],
         report <- Projects.Reporting.generate_report(project) do
      conn
      |> assign(:report, report)
      |> render("report.json")
    else
      nil ->
        conn
        |> send_resp(404, "")
    end
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
          external_id :number, "ID on external system"
          title :string, "Ticket title", required: true
          description :string, "Description"
          url :string, "URL to the bugtracker", format: "url"
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
      end,
      report: swagger_schema do
        title "Report"
        properties do
          schedule (Schema.new do
                     properties do
                       current_phase ref(:phase), "Current Phase"
                       phase_candidates_at :string, "The begin of the second phase", format: "date-time"
                       phase_start :string, "The begin of the project lifetime", format: "date-time"
                       project_end :string, "The end date of the project", format: "date-time"
                     end
          end)
          participations (Schema.new do
                           properties do
                             users :number, "The amount of users participating"
                             candidates :number, "The amount of canidates participating"
                             users_voted :number, "The amount of users that have voted"
                             candidates_voted :number, "The amount of candidates that have voted"
                           end
          end)
          votes (Schema.new do
                  properties do
                    candidates Schema.array(:report_votes_candidates), "All candidates ordered by votes received"
                    tickets Schema.array(:report_votes_tickets), "All tickets ordered by votes received"
                  end
          end)
        end
      end,
      report_votes_candidates: swagger_schema do
        properties do
          candidate ref(:report_user), "The candidate"
          votes_received :number, "The amount of votes received"
        end
      end,
      report_user: swagger_schema do
        properties do
          id :number, "User ID"
          name :string, "Username"
        end
      end,
      report_votes_tickets: swagger_schema do
        properties do
          ticket ref(:ticket), "The ticket"
          votes_received :number, "The amount of votes received"
          voted_by Schema.array(:number), "Array of user id of candidates who voted for this ticket"
        end
      end
    }
  end
end
