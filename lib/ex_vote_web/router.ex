defmodule ExVoteWeb.Router do
  use ExVoteWeb, :router

  import ExVoteWeb.Plugs.UserPlugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :ensure_token
  end

  scope "/", ExVoteWeb do
    pipe_through :browser # Use the default browser stack

    get "/", ProjectController, :index
    get "/projects/view/:id", ProjectController, :view
    post "/projects/add_user", ProjectController, :add_user
    post "/projects/add_candidate", ProjectController, :add_candidate
    post "/projects/add_user_vote", ProjectController, :add_user_vote
    post "/projects/add_candidate_vote", ProjectController, :add_candidate_vote
    post "/projects/delete_candidate_vote", ProjectController, :delete_candidate_vote

    get "/users/login", UserController, :login
    post "/users/login", UserController, :login

    get "/users/logout", UserController, :logout
  end

  scope "/api", ExVoteWeb, as: :api do
    pipe_through :api

    scope "/users" do
      post "/login", Api.UserController, :login
      post "/register", Api.UserController, :register

      scope "/" do
        pipe_through :api_auth

        get "/token_test", Api.UserController, :token_test
      end
    end

    scope "/projects" do
      resources "/", Api.ProjectController, only: [:index, :show, :create], param: "project_id"
      get "/:project_id/report", Api.ProjectController, :report
      get "/:project_id/tickets", Api.ProjectController, :list_tickets
      get "/:project_id/participations", Api.ProjectParticipationController, :list_participations
      get "/:project_id/participations/candidates", Api.ProjectParticipationController, :list_candidates
      get "/:project_id/participations/users", Api.ProjectParticipationController, :list_users

      scope "/" do
        pipe_through :api_auth

        get "/:project_id/participations/current", Api.ProjectParticipationController, :show_current_participation
        post "/:project_id/participations/current", Api.ProjectParticipationController, :create_current_participation
        put "/:project_id/participations/current", Api.ProjectParticipationController, :update_current_participation
        get "/:project_id/participations/current/votes", Api.ProjectParticipationController, :list_votes
        put "/:project_id/participations/current/votes", Api.ProjectParticipationController, :update_votes
      end
    end
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :ex_vote, swagger_file: "swagger.json"
  end

  scope "/api/redoc" do
    get "/", ExVoteWeb.Api.RedocController, :index
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "ExVote API"
      },
      tags: [
        %{
          name: "Projects",
          description: """
          Project contains information about the lifecycle of a participation project. This resource is the base for all participation endpoints.

          For further informations regarding participations see Participations.
          """
        },
        %{
          name: "Users",
          description: "Users are participants in a project. They can vote for candidates, whereas candidates can vote directly for Tickets (requirements)"
        },
        %{
          name: "Project Participations",
          description: """
          Participation represents the voting process. A Participation is an unique relationship between a user (including candidates) and a project.

          For the users currently participating in the a project see Current Participation.
          """
        },
        %{
          name: "Current Participation",
          description: """
          Current Participation describes the participation of an authenticated user (including candidates) in a project.

          The Participation changes according to the current phase of the project.

          - Users vote for a single candidate during the User phase of the project.

          - Candidate vote for none, one, or several tickets (requirements) during the candidate phase of the project.

          """
        }
      ],
      securityDefinitions: %{
        ApiKey: %{
          type: "apiKey",
          name: "Authorization",
          in: "header",
          description: "Token for API operations"
        }
      },
      security: [
        %{ApiKey: []}
      ]
    }
  end
end
