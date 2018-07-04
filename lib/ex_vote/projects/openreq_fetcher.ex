defmodule ExVote.Projects.OpenreqFetcher do
  use Task

  require Logger
  import NaiveDateTime

  @url "http://openreq.ist.tugraz.at/api/v1/project/3NjfP3cf/unassigned"

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    Logger.debug("Fetching OpenREQ project...")
    HTTPoison.start()

    {:ok, %{body: body}} = HTTPoison.get(@url)
    Logger.debug("Adding OpenREQ project to database...")
    {:ok, answer} = Poison.decode(body)
    project = create_project(answer)
    {:ok, _project} = ExVote.Projects.create_project(project)
  end

  defp create_project(answer) do
    %{
      phase_candidates: utc_now(),
      phase_end: add(utc_now(), 60 * 60 * 24 * 7),
      title: "OpenREQ",
      tickets: Enum.map(answer["requirements"], &to_ticket/1)
    }
  end

  defp to_ticket(requirement) do
    %{
      external_id: requirement["id"],
      title: requirement["title"],
      description: requirement["description"]
    }
  end
end
