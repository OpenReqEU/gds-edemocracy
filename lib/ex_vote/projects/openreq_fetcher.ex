defmodule ExVote.Projects.OpenreqFetcher do
  use Task

  require Logger
  import NaiveDateTime

  @url "http://217.172.12.199:9001/api/v1/project/3NjfP3cf/unassigned"

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    Logger.debug("Fetching OpenReq project...")
    HTTPoison.start()

    {:ok, %{body: body}} = HTTPoison.get(@url)
    Logger.debug("Adding OpenReq project to database...")
    {:ok, answer} = Poison.decode(body)
    project = create_project(answer)
    {:ok, project} = ExVote.Projects.create_project(project)

    project
    |> candidate_participation()
    |> ExVote.Participations.create_participation()
  end

  defp create_project(answer) do
    %{
      phase_candidates: utc_now(),
      phase_end: add(utc_now(), 60 * 60 * 24 * 7),
      title: "OpenReq",
      tickets: Enum.map(answer["requirements"], &to_ticket/1)
    }
  end

  defp candidate_participation(%{id: project_id}) do
    %{id: user_id} = ExVote.Accounts.find_user("candidate");
    %{
      user_id: user_id,
      project_id: project_id,
      role: "candidate",
      candidate_summary: "Vote for me"
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
