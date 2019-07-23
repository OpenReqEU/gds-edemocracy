defmodule ExVoteWeb.Api.UserView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

  def render("success.json", %{:login => login}) do
    %{
      token: login.token,
      id: login.id
    }
  end

  def render("register.json", %{:user => user}) do
    %{
      id: user.id,
      name: user.name
    }
  end
end
