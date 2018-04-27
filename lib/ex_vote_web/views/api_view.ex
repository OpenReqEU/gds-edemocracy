defmodule ExVoteWeb.ApiView do
  use ExVoteWeb, :view

  def render("show.json", %{:project => project}) do
    %{
      title: project.title,
      phase_candidates_at: project.phase_candidates,
      phase_end_at: project.phase_end,
      tickets: Enum.map(project.tickets, &ticket_json/1)
    }
  end

  def render("error.json", %{:changeset => changeset}) do
    errors =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg,_opts} -> msg end)

    %{
      errors: Enum.map(errors, &error_json/1)
    }
  end

  defp ticket_json(ticket) do
    %{
      title: ticket.title,
      url: ticket.url
    }
  end

  defp error_json({field, [message]}) do
    %{
      field => error_message_json(message)
    }
  end

  defp error_message_json(messages) when is_map(messages) do
    Enum.reduce(messages, %{}, fn (error, acc) ->
      Map.merge(acc, error_json(error))
    end)
  end

  defp error_message_json(message), do: message

end
