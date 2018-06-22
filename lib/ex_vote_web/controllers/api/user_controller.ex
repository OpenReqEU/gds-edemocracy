defmodule ExVoteWeb.Api.UserController do
  use ExVoteWeb, :controller
  use PhoenixSwagger

  alias ExVote.Accounts

  swagger_path :login do
    summary "User login"
    description "Returns an authentication token"
    security []
    parameters do
      body :body, Schema.ref(:user_login), "User Login", required: true
    end
    response 200, "OK"
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
    summary "Token test"
    description "Tests the token present in the authorization header"
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
      end
    }
  end
end
