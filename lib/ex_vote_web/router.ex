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
    get "/users/login", UserController, :login
    post "/users/login", UserController, :login
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExVoteWeb do
  #   pipe_through :api
  # end
end
