defmodule ExVoteWeb.Api.UserController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  alias ExVote.Accounts

  swagger_path :login do
    summary "User login"
    description "Authenticates a user"
    tag "Users"
    security []
    produces "application/json"
    parameters do
      body :body, Schema.ref(:user_login), "User Login", required: true
    end
    response 200, "OK", Schema.ref(:token_container)
    response 400, "Login failed"
  end

  def login(conn, params) do
    case Accounts.login(params) do
      {:ok, user} ->
        token = ExVoteWeb.Tokens.sign(user.id)
        conn
        |> assign(:token, token)
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
    description "Tests the token present in the authorization header"
    tag "Users"
    produces "text/plain"
    response 200, "OK"
    response 401, "Authentication required"
  end

  def token_test(conn, _params) do
    text(conn, "ok")
  end

  def swagger_definitions do
    %{
      user_login: swagger_schema do
        title "UserLogin"
        description "Informations to perform a login"
        properties do
          name :string, "Username", required: true
        end
      end,
      token_container: swagger_schema do
        title "Token"
        description "Contains the authentication token"
        properties do
          token :string, "Token"
        end
      end
    }
  end
end
