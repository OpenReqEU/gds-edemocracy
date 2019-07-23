defmodule ExVoteWeb.Api.UserController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  alias ExVote.Accounts

  swagger_path :login do
    summary "Login different types of users in the system"
    description "Authenticate the user to allow to take part in participation projects. The available actions will depend on the the user type (user and candidate)."
    tag "Users"
    security []
    produces "application/json"
    parameters do
      body :body, Schema.ref(:user_login), "User login", required: true
    end
    response 200, "OK", Schema.ref(:token_container)
    response 400, "Login failed"
  end

  def login(conn, params) do
    case Accounts.login(params) do
      {:ok, user} ->
        token = ExVoteWeb.Tokens.sign(user.id)
	login = %{id: user.id, token: token}
        conn
        |> assign(:login, login)
        |> render("success.json")
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(400)
        |> render("error.json")
    end
  end

  swagger_path :token_test do
    summary "Test authentication"
    description "Used to tests the token in the authorization header. The token is needed to access API endpoints that need authorization."
    tag "Users"
    response 200, "OK"
    response 401, "Authentication required"
  end

  def token_test(conn, _params) do
    text(conn, "ok")
  end

  swagger_path :register do
    summary "Register a user"
    security []
    description "Add a new user in the ExVote application"
    produces "application/json"
    parameters do
      body :body, Schema.ref(:user_login), "New user", required: true
    end
    tag "Users"
    response 200, "OK", Schema.ref(:new_user)
    response 400, "Error"
  end
  def register(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        conn
        |> assign(:user, user)
        |> render("register.json")

      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> put_status(400)
        |> render("error.json")
    end
  end

  def swagger_definitions do
    %{
      user_login: swagger_schema do
        title "UserLogin"
        description "Information necessary to login a user"
        properties do
          name :string, "Username", required: true
        end
      end,
      token_container: swagger_schema do
        title "Token"
        description "Authentication token needed to perform actions for which authorization is required"
        properties do
          token :string, "Token"
        end
      end,
      new_user: swagger_schema do
        title "User"
        description "A user of the platform. Note that its role can be futher defined using the Current Participation APIs."
        properties do
          id :number, "User ID"
          name :string, "Username"
        end
      end
    }
  end
end
