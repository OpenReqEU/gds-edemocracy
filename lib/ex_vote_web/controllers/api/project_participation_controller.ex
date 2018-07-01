defmodule ExVoteWeb.Api.ProjectParticipationController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  import ExVoteWeb.Plugs.ProjectPlugs
  import ExVoteWeb.Plugs.ParticipationPlugs

  alias ExVote.Participations

  plug :fetch_project
  plug :fetch_current_participation when action in [
    :show_current_participation,
    :update_current_participation,
    :list_votes,
    :update_votes
  ]

  swagger_path :list_candidates do
    summary "Retrieve a list of all participating candidates"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.array(:"candidate")
    response 400, "Error"
  end

  def list_candidates(conn, _params) do
    conn.assigns[:project]
    |> Participations.get_participations("candidate")
    |> render_participations(conn)
  end

  swagger_path :list_users do
    summary "Retrieve a list of all participating users"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 200, "OK", Schema.array(:"user")
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
    response 200, "OK", Schema.ref(:participation_list)
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
    description """
    The kind of votes are dependent on the participation role, hence the votes are contained in a variable schema, selected by the "type" field.
    See [Composition and Inheritance](https://swagger.io/specification/v2/).
    """
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
    end
    response 404, "User has no participation"
    response 200, "OK", Schema.ref(:votes_container)
  end

  def list_votes(conn, _params) do
    if participation = conn.assigns[:participation] do
      votes = Participations.get_votes(participation)
      conn
      |> assign(:votes, votes)
      |> render_votes(participation)
    else
      send_resp(conn, 404, "")
    end
  end

  defp render_votes(conn, %Participations.UserParticipation{}), do: render(conn, "votes_users.json")
  defp render_votes(conn, %Participations.CandidateParticipation{}), do: render(conn, "votes_tickets.json")

  swagger_path :update_votes do
    summary "Update the current participations votes"
    description """
    The id of each vote references different entities, based on the participation type.

    - user: References a candidate in the project by user_id (limited to exactly one element)

    - candidate: References a ticket in the project by ticket_id
    """
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project id", required: true
      body :body, Schema.ref(:votes), "Votes", required: true
    end
  end
  def update_votes(conn, params) do
    with participation when not is_nil(participation) <- conn.assigns[:participation],
         {:ok, votes} <- Participations.update_votes(participation, params) do
      conn
      |> assign(:votes, votes)
      |> render_votes(participation)
    else
      nil ->
        send_resp(conn, 404, "")
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(200)
        |> render("error.json")
    end
  end

  def swagger_definitions do
    %{
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
      participation_list: swagger_schema do
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
      votes_container: swagger_schema do
        title "Votes"
        discriminator "type"
        properties do
          type ref(:votes_type), "Type"
        end
      end,
      votes_type: swagger_schema do
        type :string
        title "Type of votes"
        enum ["participations", "tickets"]
      end,
      "tickets": swagger_schema do
        title "Vote container for Tickets"
        all_of [
          Schema.ref(:votes_container),
          Schema.new do
            property :votes, Schema.ref(:ticket_list), "Votes"
          end
        ]
      end,
      "participations": swagger_schema do
        title "Vote container for participations"
        all_of [
          Schema.ref(:votes_container),
          Schema.new do
            property :votes, Schema.ref(:participation_list), "Votes"
          end
        ]
      end,
      votes: swagger_schema do
        title "Votes"
        properties do
          votes Schema.array(:integer), "Votes"
        end
      end
    }
  end
end
