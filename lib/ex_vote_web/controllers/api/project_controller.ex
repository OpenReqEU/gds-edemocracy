defmodule ExVoteWeb.Api.ProjectController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  import ExVoteWeb.Plugs.ProjectPlugs

  alias ExVote.Projects
  alias ExVote.Repo

  plug :fetch_project

  swagger_path :index do
    summary "Return the list of all participation projects"
    description "The list includes projects in any phase, including the completed ones."
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
    summary "Return a report for the status of a single participation project."
    description "Returns a report containing information on the status of an existing project. The project must exist. Other values will generate an exception"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Return a single participation project"
    description "The project must exist. Other values will generate an exception"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
    end
    response 200, "OK", Schema.ref(:project)
    response 404, "Project not found"
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
    summary "Create a new participation project"
    tag "Projects"
    security []
    produces "application/json"
    parameters do
      body :body, Schema.ref(:project), "Project ID", required: true
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
    summary "Return a list of tickets (requirements) included in a participation project."
    tag "Projects"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
          phase_candidates :string, "Time when the voting for candidates in this participation project should start", required: true, format: "date-time"
          phase_end :string, "Time when the participation project should end", required: true, format: "date-time"
          tickets Schema.ref(:ticket_list)
        end
      end,
      short_project: swagger_schema do
        title "Short project"
        description "A short overview of a participation project"
        properties do
          id :number, "Project id (readonly)"
          title :string, "Project title", required: true
          current_phase ref(:phase), "Current phase", required: true
        end
      end,
      project_list: swagger_schema do
        title "Project list"
        description "The list of participation projects in short format"
        type :array
        items Schema.ref(:short_project)
      end,
      ticket: swagger_schema do
        title "Ticket"
        description "A single ticket (requirement) imported from an external system"
        properties do
          id :number, "Ticket ID (readonly)"
          external_id :number, "Ticket ID on the external system"
          title :string, "Ticket (requirement) title", required: true
          description :string, "Description of the Ticket (requirement) content"
          url :string, "URL representing the source of the ticket (requirement)", format: "url"
        end
      end,
      ticket_list: swagger_schema do
        title "Tickets (requirements)"
        description "A list of tickets (requirements) imported from an external system"
        type :array
        items Schema.ref(:ticket)
      end,
      phase: swagger_schema do
        type :string
        title "Phase"
        description """
        A phase during a participation project.

        - In a User phase, normal users vote for candidates,
        - In a Candidate phase, elected candidates vote for Tickets (requirements),
        - The End phase concludes the voting process.
        """
        enum ["phase_users", "phase_candidates", "phase_end"]
      end,
      report: swagger_schema do
        title "Report"
        description """
        A report describing a participation project in terms of:
        - Votes,
        - Schedule, 
        - Users and Candidates participantion
        """
        properties do
          schedule (Schema.new do
                     title "Schedule"
                     description "Relevant times for the scheduling of a participation project" 
                     properties do
                       current_phase ref(:phase), "The current phase of a participation project"
                       phase_candidates_at :string, "The time when the elected candidates start voting", format: "date-time"
                       phase_start :string, "The time when the participation project starts", format: "date-time"
                       project_end :string, "The time when the participation project ends", format: "date-time"
                     end
          end)
          participations (Schema.new do
                           title "Participations"
                           description "Information regarding users and candidates participation in a project"
                           properties do
                             users :number, "The total number of participating users"
                             candidates :number, "The number of participating candidates"
                             users_voted :number, "The number of users who have voted for a candidate"
                             candidates_voted :number, "The number of candidates who have voted for a Ticket (requirements)"
                           end
          end)
          votes (Schema.new do
                  title "Votes"
                  description "Summary results of the voting process"
                  properties do
                    candidates Schema.array(:report_votes_candidates), "List of candidates ranked by the total number of votes received"
                    tickets Schema.array(:report_votes_tickets), "List of tickets (requirements) ordered by the total number of votes received"
                  end
          end)
        end
      end,
      report_votes_candidates: swagger_schema do
        title "Candidate votes report"
        description "Total number of votes received by a candidate"
        properties do
          candidate ref(:report_user), "The candidate"
          votes_received :number, "The number of votes received by the candidate"
        end
      end,
      report_user: swagger_schema do
        title "Generic representation of a user"
        properties do
          id :number, "User ID"
          name :string, "Username"
        end
      end,
      report_votes_tickets: swagger_schema do
        title "Ticket votes report"
        properties do
          ticket ref(:ticket), "The Ticket (requirement)"
          votes_received :number, "The number of votes received by the Ticket"
          voted_by Schema.array(:number), "List of candidates id who voted for the ticket"
        end
      end
    }
  end
end
