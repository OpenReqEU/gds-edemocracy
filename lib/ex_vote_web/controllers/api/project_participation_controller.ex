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
    summary "Return a list of all participating candidates"
    description "For an ongoing existing project, the list includes candidates participating in the project"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Return a list of all participating users"
    description "For an ongoing existing project, the list includes users participating in the project"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    description "For an ongoing existing project, the list includes all participants (users and candidates)"
    tag "Project Participations"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Retrieve the participation of the logged-in user in a project"
    description "For an ongoing existing project, return the participation role of the current user (either user or candidate). Authorization is necessary."
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Create the participation of the logged-in user in the project"
    description "For an ongoing existing project, creates a participation allowing the user currently logged-in to join the project. Authorization required."
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Updates the logged-in user participation in a project"
    description "For an existing ongoing project, allow the user to change its role. Authorization required. If updating a user to a candidate, a candidate_summary field should be passed in the body. If the participation does not exists, it will be created."
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Return the votes of the user currently logged in for a project"
    description """
    For an existing project, the votes depend on the role the user has when voting, either for a candidate or a ticket (requirement). This information is reported in the "type" field.
    """
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
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
    summary "Update the vote of the logged-in user for an ongoing participation project"
    description """
    For an existing ongoing project, the vote of the logged-in user is updated based on its current role.

    If participating as a user, the vote should contain exactly one element referencing the user_id of a candidate in the project (limited to exactly one element)

    If participating as a candidate, the vote can contain several elements referencing the selected ticket_ids
    """
    tag "Current Participation"
    produces "application/json"
    parameters do
      project_id :path, :integer, "Project ID", required: true
      body :body, Schema.ref(:votes), "Votes", required: true
    end
  end
  def update_votes(conn, params) do
    params = Map.put(params, "user_id", conn.assigns.user.id)
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
        description "Represents the user participation in a project depending on its role"
        discriminator "role"
        properties do
          project_id :number, "Project ID (readonly)"
          user_id :number, "User ID (readonly)"
          role ref(:role), "Role", required: true
        end
      end,
      "candidate": swagger_schema do
        title "candidate"
        description "Participation for a candidate"
        all_of [
          Schema.ref(:participation),
          Schema.new do
            property :candidate_summary, :string, "Candidate statement on its participation in the project (only relevant for role: candidate)", required: true
          end
        ]
      end,
      "user": swagger_schema do
        title "user"
        description "Participation for a user"
        all_of [
          Schema.ref(:participation)
        ]
      end,
      participation_list: swagger_schema do
        title "Participations"
        description "A collection of users and candidates participating to a project"
        type :array
        items Schema.ref(:participation)
      end,
      role: swagger_schema do
        type :string
        title "Role"
        description "The role of a participant in a project. Users vote for candidates. Candidates vote for tickets (requirements)."
        enum ["user", "candidate"]
      end,
      votes_container: swagger_schema do
        title "Votes"
        description "Votes in a participation project."
        discriminator "type"
        properties do
          type ref(:votes_type), "Type"
        end
      end,
      votes_type: swagger_schema do
        title "Type of votes"
        description "The type depends on whether the vote was casted by a user or a candidate."
        type :string
        enum ["participations", "tickets"]
      end,
      "tickets": swagger_schema do
        title "Vote for tickets (requirements)"
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
