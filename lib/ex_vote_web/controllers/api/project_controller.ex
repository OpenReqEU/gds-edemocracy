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
    :update_current_participation
  ]

  swagger_path :index do
    summary "All projects"
    description "Lists all projects"
    security []
    response 200, "OK", Schema.ref(:project_list)
  end

  def index(conn, _params) do
    conn
    |> assign(:projects, Projects.list_projects())
    |> render("index.json")
  end

  swagger_path :show do
    summary "Get project informations"
    description "Returns a project"
    security []
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
    summary "Add a new project"
    description "Creates a new project\n Please note that the id fields are ignored on creation"
    security []
    parameters do
      body :body, Schema.ref(:project), "The project", required: true
    end
    response 200, "OK"
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

  swagger_path :join do
    summary "Join a project"
    description "Creates a Participation in the specified project with the current user (identified by Authorization token)"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:participation), "The participation details", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 400, "Error"
  end

  def join(conn, params) do
    user = conn.assigns[:user]
    params = Map.put(params, "user_id", user.id)

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

  swagger_path :change_role do
    summary "Change a users role"
    description "Changes the current users role to candidate"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:role), "Role information", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 400, "Error"
  end
  def change_role(conn, params) do
    user = conn.assigns[:user]
    params = Map.put(params, "user_id", user.id)

    case Projects.change_role_to_candidate(params) do
      {:ok, participation} ->
        conn
        |> assign(:participation, participation)
        |> render("participation.json")
      {:error, error} when is_binary(error) ->
        conn
        |> json(%{error: error})
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(400)
        |> render("error.json")
    end
  end

  swagger_path :list_candidates do
    summary "List all candidates"
    description "Returns all candidates for the specified project"
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
    summary "List all users"
    description "Returns all users for the specified project"
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
    summary "List all participations"
    description "Returns all participations for the specified project"
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
    summary "List all tickets"
    description "Returns all tickets for the specified project"
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
    summary "Shows the participation for the current user and project"
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
    summary "Creates a new participation for the current user and project"
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
    summary "Updates the current participation"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:participation), "Participation", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 404, "User has no participation"
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
        send_resp(conn, 404, "")
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("error.json")
    end
  end

  def swagger_definitions do
    %{
      project: swagger_schema do
        title "Project"
        description "A participation project"
        properties do
          id :number, "Project id"
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
          id :number, "Project id", required: true
          title :string, "Project title", required: true
          current_phase :string, "Current Phase", required: true
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
          id :number, "Ticket id"
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
        properties do
          project_id :number, "Project id"
          user_id :number, "User id"
          role :string, "Role", required: true
          candidate_summary :string, "Summary text (only relevant for role: candidate)"
        end
      end,
      participations: swagger_schema do
        title "Participations"
        description "A collection of participations"
        type :array
        items Schema.ref(:participation)
      end,
      role: swagger_schema do
        title "Role"
        description "Describes a Role"
        properties do
          role :string, "Role", required: true
          candidate_summary :string, "Summary text (only relevant for role: candidate)", required: true
        end
      end
    }
  end
end
