defmodule ExVoteWeb.Api.UserView do
  use ExVoteWeb, :view

  def render("error.json", %{:changeset => changeset}), do: render_changeset_errors(changeset)

  def render("success.json", %{:token => token}) do
    %{
      token: token
    }
  end
end
