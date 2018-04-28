defmodule ExVoteWeb.ProjectController do
  use ExVoteWeb, :controller

  alias ExVote.Projects
  alias ExVote.Participations

  def index(conn, _params) do
    projects = Projects.list_projects()

    conn
    |> assign(:projects, projects)
    |> render("index.html")
  end

  def view(conn, %{"id" => project_id}) do
    project = Projects.get_project(project_id, [:participations, :tickets])

    conn =
      case Map.get(conn.assigns, :user) do
        nil -> conn
        user -> assign(conn, :participation, Participations.get_participation(project, user))
      end

    conn
    |> assign(:project, project)
    |> render("view.html")
  end

  def add_user(conn, %{"user_participation" => participation}) do
    case Projects.add_user(participation) do
      {:ok, participation} ->
        conn
        |> put_flash(:info, "You successfully joined the project as a user!")
        |> redirect(to: project_path(conn, :view, participation.project_id))
      {:error, changeset} ->
        redirect_url =
          if project_id = Ecto.Changeset.get_field(changeset, :project_id) do
            project_path(conn, :view, project_id)
          else
            project_path(conn, :index)
          end

        conn
        |> put_flash(:error, "Failed to join project")
        |> redirect(to: redirect_url)
    end
  end

  def add_candidate(conn, %{"candidate_participation" => participation}) do
    case Projects.add_candidate(participation) do
      {:ok, participation} ->
        conn
        |> put_flash(:info, "You successfully joined the project as a candidate!")
        |> redirect(to: project_path(conn, :view, participation.project_id))
      {:error, changeset} ->
        redirect_url =
          if project_id = Ecto.Changeset.get_field(changeset, :project_id) do
            project_path(conn, :view, project_id)
          else
            project_path(conn, :index)
          end

        conn
        |> put_flash(:error, "Failed to join project")
        |> redirect(to: redirect_url)
    end
  end

  def add_user_vote(conn, %{"user_participation" => participation}) do
    case Projects.add_user_vote(participation) do
      {:ok, participation} ->
        conn
        |> put_flash(:info, "Your vote has been received!")
        |> redirect(to: project_path(conn, :view, participation.project_id))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update vote")
        |> redirect(to: "/")
    end
  end

  def add_candidate_vote(conn, %{"participation_ticket" => participation}) do
    case Projects.add_candidate_vote(participation) do
      {:ok, _participation_with_vote} ->
        conn
        |> put_flash(:info, "Your vote has been received!")
        |> redirect(to: project_path(conn, :view, participation["project_id"]))
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to update vote")
        |> redirect(to: "/")
    end
  end

  def delete_candidate_vote(conn, %{"participation_ticket_id" => id, "project_id" => project_id}) do
    Projects.delete_candidate_vote(String.to_integer(id))

    conn
    |> redirect(to: project_path(conn, :view, project_id))
  end
end
