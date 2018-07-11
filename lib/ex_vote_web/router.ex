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
          A project contains all informations belonging to the lifecycle of a participation project. This resource is also the base of all participation endpoints.

          For further informations regarding participations see [Project Participations](#tag/Project-Participations) and [Current Participation](#tag/Current-Participation).
          """
        },
        %{
          name: "Users",
          description: "Mainly for login purposes"
        },
        %{
          name: "Project Participations",
          description: """
          A Project Participation is a participation belonging to a certain project. A Participation is unique per user and project and is the main primitive in the voting process.

          For the users participation in the selected project see [Current Participation](#tag/Current-Participation).
          """
        },
        %{
          name: "Current Participation",
          description: """
          The Current Participation describes the unique participation of the authenticated user in the selected project.

          A Participation may be one of two different types, which influences the indiviual voting process:

          - user:
          Votes on a single candidate during the first project phase.

          - candidate:
          Votes on none or multiple tickets during the second project phase.

          """
        }
      ],
      securityDefinitions: %{
        ApiKey: %{
          type: "apiKey",
          name: "Authorization",
          in: "header",
          description: "Token for Api operations"
        }
      },
      security: [
        %{ApiKey: []}
      ]
    }
  end
end
