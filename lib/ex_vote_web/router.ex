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

  scope "/", ExVoteWeb do
    pipe_through :browser # Use the default browser stack

    get "/", ProjectController, :index
    get "/projects/view/:id", ProjectController, :view
    post "/projects/add_user", ProjectController, :add_user
    post "/projects/add_candidate", ProjectController, :add_candidate
    post "/projects/add_user_vote", ProjectController, :add_user_vote
    post "/projects/add_candidate_vote", ProjectController, :add_candidate_vote

    get "/users/login", UserController, :login
    post "/users/login", UserController, :login

    get "/users/logout", UserController, :logout
  end

  scope "/api", ExVoteWeb do
    pipe_through :api

    resources "/projects", ApiController, only: [:show]
  end

  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :ex_vote, swagger_file: "swagger.json"
  end

  def swagger_info do
    %{
      info: %{
        version: "1.0",
        title: "ExVote API"
      },
      basePath: "/api"
    }
  end
end
