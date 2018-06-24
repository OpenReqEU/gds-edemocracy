defmodule ExVoteWeb.Api.ProjectController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  import ExVoteWeb.Plugs.ProjectPlugs
  import ExVoteWeb.Plugs.ParticipationPlugs

  alias ExVote.Projects
  alias ExVote.Participations
  alias ExVote.Repo

  plug :fetch_project
  plug :fetch_current_participation when action in [
    :show_current_participation,
    :update_current_participation,
    :list_votes
  ]

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

  swagger_path :list_candidates do
    summary "Retrive a list of all participating candidates"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:participations)
    response 400, "Error"
  end

  def list_candidates(conn, _params) do
    conn.assigns[:project]
    |> Participations.get_participations("candidate")
    |> render_participations(conn)
  end

  swagger_path :list_users do
    summary "Retrive a list of all participating users"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:participations)
    response 400, "Error"
  end

  def list_users(conn, _params) do
    conn.assigns[:project]
    |> Participations.get_participations("user")
    |> render_participations(conn)
  end

  swagger_path :list_participations do
    summary "Retrieve a list of all participations"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:participations)
    response 400, "Error"
  end

  def list_participations(conn, _params) do
    conn.assigns[:project]
    |> Participations.get_participations()
    |> render_participations(conn)
  end

  defp render_participations(participations, conn) do
    conn
    |> assign(:participations, participations)
    |> render("participations.json")
  end

  swagger_path :list_tickets do
    summary "Retrieve a list of all tickets"
    tag "Projects"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:tickets)
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

  swagger_path :show_current_participation do
    summary "Retrieve the current participation"
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 404, "User has no participation"
  end

  def show_current_participation(conn, _params) do
    if conn.assigns[:participation] do
      render(conn, "participation.json")
    else
      send_resp(conn, 404, "")
    end
  end

  swagger_path :create_current_participation do
    summary "Create the current participation"
    description "Mental model: Joining a project"
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:participation), "Participation", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 400, "Participation already exists"
  end

  def create_current_participation(conn, params) do
    params = Map.put(params, "user_id", conn.assigns.user.id)
    case Participations.create_participation(params) do
      {:ok, participation} ->
        conn
        |> assign(:participation, participation)
        |> render("participation.json")
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(400)
        |> render("error.json")
    end
  end

  swagger_path :update_current_participation do
    summary "Create or alter the current participation"
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:participation), "Participation", required: true
    end
    response 200, "OK", Schema.ref(:participation)
  end

  def update_current_participation(conn, params) do
    with participation when not is_nil(participation) <- conn.assigns[:participation],
         params <- Map.put(params, "user_id", conn.assigns.user.id),
         {:ok, participation} <- Participations.update_participation(participation, params) do
      conn
      |> assign(:participation, participation)
      |> render("participation.json")
    else
      nil ->
        conn
        |> create_current_participation(params)
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("error.json")
    end
  end

  swagger_path :list_votes do
    summary "Retrieve a list of the current participations votes"
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 404, "User has no participation"
    response 200, "OK"
  end

  def list_votes(conn, _params) do
    if participation = conn.assigns[:participation] do
      conn
      |> render_votes(participation)
    else
      send_resp(conn, 404, "")
    end
  end

  def render_votes(conn, %Participations.UserParticipation{} = participation) do
    votes = Participations.get_votes(participation)

    conn
    |> assign(:users, votes)
    |> render("users.json")
  end

  def render_votes(conn, %Participations.CandidateParticipation{} = participation) do
    votes = Participations.get_votes(participation)

    conn
    |> assign(:tickets, votes)
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
          tickets Schema.ref(:tickets)
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
      tickets: swagger_schema do
        title "Tickets"
        description "A collection of tickets"
        type :array
        items Schema.ref(:ticket)
      end,
      participation: swagger_schema do
        title "Participation"
        description "Represents a participation in a project"
        discriminator "role"
        properties do
          project_id :number, "Project id (readonly)"
          user_id :number, "User id (readonly)"
          role ref(:role), "Role", required: true
        end
      end,
      "candidate": swagger_schema do
        title "candidate"
        description "Candidate"
        all_of [
          Schema.ref(:participation),
          Schema.new do
            property :candidate_summary, :string, "Summary text (only relevant for role: candidate)", required: true
          end
        ]
      end,
      "user": swagger_schema do
        title "user"
        description "user"
        all_of [
          Schema.ref(:participation)
        ]
      end,
      participations: swagger_schema do
        title "Participations"
        description "A collection of participations"
        type :array
        items Schema.ref(:participation)
      end,
      role: swagger_schema do
        type :string
        title "Role"
        enum ["user", "candidate"]
      end,
      phase: swagger_schema do
        type :string
        title "Phase"
        enum ["phase_users", "phase_candidates", "phase_end"]
      end
    }
  end
end
