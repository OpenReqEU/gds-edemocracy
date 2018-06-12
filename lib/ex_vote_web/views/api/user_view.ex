defmodule ExVoteWeb.Api.UserView do
  use ExVoteWeb, :view

  def render("success.json", %{:token => token}) do
    %{
      token: token
    }
  end

  def render("error.json", %{:changeset => changeset}) do
    errors =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)

    %{
      errors: Enum.map(errors, &error_json/1)
    }
  end
end
