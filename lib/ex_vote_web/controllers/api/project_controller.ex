defmodule ExVoteWeb.Api.ProjectController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  swagger_path :show do
    get "/projects/{id}"
    summary "Get project informations"
    description "Returns a project"
    security []
    parameters do
      id :path, :integer, "ID of project to return", required: true
    end
    response 200, "OK", Schema.ref(:project)
    response 404, "Not found"
  end

  def show(conn, %{"id" => project_id}) do
    project = ExVote.Projects.get_project(project_id, [:tickets])

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
    post "/projects"
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
    case ExVote.Projects.create_project(params) do
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
    post "/projects/{id}/join"
    summary "Join a project"
    description "Creates a Participation in the specified project with the current user (identified by Authorization token)"
    parameters do
      id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:participation), "The participation details", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 400, "Error"
  end
  def join(conn, params) do
    user = Map.fetch!(conn.assigns, :user)
    {project_id, params} = Map.pop(params, "id")
    participation =
      params
      |> Map.put("user_id", user.id)
      |> Map.put("project_id", project_id)

    case ExVote.Participations.create_participation(participation) do
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
    post "/projects/{id}/changerole"
    summary "Changes a users role"
    description "Changes the current users role to candidate"
    parameters do
      id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:role), "Role information", required: true
    end
    response 200, "OK", Schema.ref(:participation)
    response 400, "Error"
  end
  def change_role(conn, params) do
    user = Map.fetch!(conn.assigns, :user)
    {project_id, params} = Map.pop(params, "id")
    role_change =
      params
      |> Map.put("user_id", user.id)
      |> Map.put("project_id", project_id)

    case ExVote.Projects.change_role_to_candidate(role_change) do
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
