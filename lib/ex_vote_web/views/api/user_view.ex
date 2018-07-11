defmodule ExVoteWeb.Api.UserView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

  def render("success.json", %{:token => token}) do
    %{
      token: token
    }
  end

  def render("register.json", %{:user => user}) do
    %{
      id: user.id,
      name: user.name
    }
  end
end
