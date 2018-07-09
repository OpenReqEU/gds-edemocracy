defmodule ExVote.Projects.Reporting do
  alias ExVote.Projects.Project
  alias ExVote.Projects.Reporting.Report
  alias ExVote.Participations
  alias ExVote.Participations.{UserParticipation, CandidateParticipation}
  alias ExVote.Repo

  def generate_report(%Project{} = project) do
    participations =
      Participations.get_participations(project)
      |> Enum.group_by(&participation_type/1)
      |> Map.update(:candidates, [], &Repo.preload(&1, votes_candidate: [:ticket]))
      |> Map.update(:users, [], &Repo.preload(&1, :vote_user))

    project = Repo.preload(project, :tickets)

    %Report{}
    |> populate_schedule(project)
    |> populate_participations(participations)
    |> populate_votes(project, participations)
  end

  defp participation_type(%UserParticipation{}), do: :users
  defp participation_type(%CandidateParticipation{}), do: :candidates

  defp populate_schedule(report, project) do
    %{
      current_phase: current_phase,
      phase_candidates: phase_candidates,
      inserted_at: project_start,
      phase_end: project_end
    } = project

    schedule = %{
      current_phase: Atom.to_string(current_phase),
      phase_candidates_at: phase_candidates,
      project_start: project_start,
      project_end: project_end
    }

    %Report{report | schedule: schedule}
  end

  defp populate_participations(report, %{candidates: candidates, users: users}) do
    participations = %{
      users: length(users),
      candidates: length(candidates),
      users_voted: Enum.count(users, &voted?/1),
      candidates_voted: Enum.count(candidates, &voted?/1)
    }

    %Report{report | participations: participations}
  end

  defp voted?(%UserParticipation{vote_user_id: nil}), do: false
  defp voted?(%UserParticipation{}), do: true
  defp voted?(%CandidateParticipation{votes_candidate: votes}) when length(votes) === 0, do: false
  defp voted?(%CandidateParticipation{}), do: true

  defp populate_votes(report, %{tickets: tickets}, %{users: users, candidates: candidates}) do
    ticket_votes =
      candidates
      |> format_votes()
      |> Enum.map(fn [head | _] = votes -> vote_container(:ticket, head, votes) end)

    missing_ticket_votes =
      tickets
      |> Enum.reject(fn %{id: id} ->
        Enum.any?(ticket_votes, fn %{ticket: %{id: vote_id}} -> id === vote_id end)
      end)
      |> Enum.map(&vote_container(:ticket, &1, 0))

    ticket_votes =
      ticket_votes
      |> Enum.concat(missing_ticket_votes)
      |> Enum.sort(&compare_votes/2)

    candidate_votes =
      users
      |> format_votes()
      |> Enum.map(fn [head | _] = votes -> vote_container(:candidate, head, votes) end)

    missing_candidate_votes =
      candidates
      |> Enum.reject(fn %{user: %{id: id}} ->
        Enum.any?(candidate_votes, fn %{candidate: %{id: vote_id}} -> id === vote_id end)
      end)
      |> Enum.map(fn %{user: candidate} -> vote_container(:candidate, candidate, 0) end)

    candidate_votes =
      candidate_votes
      |> Enum.concat(missing_candidate_votes)
      |> Enum.sort(&compare_votes/2)

    %Report{report | votes: %{tickets: ticket_votes, candidates: candidate_votes}}
  end

  defp format_votes(participations) do
    participations
    |> Enum.reduce([], &accumulate_votes/2)
    |> Enum.group_by(fn %{id: id} -> id end)
    |> Map.values()
  end

  defp accumulate_votes(%UserParticipation{vote_user: vote}, acc) when is_nil(vote), do: acc
  defp accumulate_votes(%UserParticipation{vote_user: vote}, acc), do: [vote | acc]

  defp accumulate_votes(%CandidateParticipation{votes_candidate: votes}, acc),
    do: Enum.map(votes, &Map.get(&1, :ticket)) ++ acc

  defp vote_container(type, value, votes) when is_list(votes),
    do: vote_container(type, value, length(votes))

  defp vote_container(type, value, votes) do
    %{
      type => value,
      :votes_received => votes
    }
  end

  defp compare_votes(%{votes_received: votes_left}, %{votes_received: votes_right}),
    do: votes_left >= votes_right
end
