defmodule ExVote.Seeder do
  import NaiveDateTime

  alias ExVote.Projects
  alias ExVote.Accounts

  @titles [
    "Lorem ipsum dolor sit amet, class nec, eget dictum mattis, vulputate enim ut.",
    "Odio dolor.",
    "Nostra nullam ipsum.",
    "Sapien sem turpis, sit penatibus donec.",
    "Mattis placerat, adipiscing diam velit.",
    "Et in orci, suspendisse ut cum.",
    "Elit sit.",
    "Sagittis magna quis.",
    "Nulla ac libero, cursus aliquam, eget leo.",
    "Arcu sit, at tortor posuere, aliquam arcu.",
    "Enim tincidunt, sed condimentum.",
    "Urna vitae varius, sit turpis, dis morbi.",
    "Aenean ornare iusto.",
    "Dolor urna, arcu sed pede, nec quis.",
    "Mollis diam mattis.",
    "Turpis elit porta, libero tellus.",
    "Nisl feugiat.",
    "Vel duis, sociis in justo.",
    "Wisi at, dignissim tincidunt ipsum, neque enim.",
    "Rhoncus amet praesent, et feugiat auctor.",
    "Fusce vitae, ac ligula, pellentesque turpis.",
    "Mollis suspendisse.",
    "Praesent dictumst.",
    "Diam mi, scelerisque donec sed.",
    "Morbi cursus parturient.",
    "Et id, ac eros.",
    "Est purus, nonummy tellus sit, nullam hac quam.",
    "Enim luctus.",
    "Diam velit sit.",
    "Nec quam ut, dolor sit vehicula, odio viverra vel.",
    "Fusce id.",
    "Mollis duis, donec faucibus.",
    "Non leo, eget nulla quis.",
    "Tellus proin malesuada, arcu aliquet.",
    "In dolor mauris, vehicula elit.",
    "Nec molestie integer.",
    "Ut phasellus eleifend, vivamus recusandae, etiam elit.",
    "Et et.",
    "Eros sollicitudin, ac pellentesque.",
    "Ut justo et, ridiculus magna.",
    "Nec volutpat, volutpat at egestas, lectus lobortis.",
    "Et a.",
    "At orci, lectus non, a bibendum volutpat.",
    "Massa amet, convallis in.",
    "Mauris velit a.",
    "Nullam mauris quisque, ultrices sollicitudin accumsan, convallis egestas ut.",
    "Nibh sem in, amet urna, aenean metus.",
    "Sed vestibulum montes, a massa arcu, vel libero nunc.",
    "Feugiat eu.",
    "Sapien wisi augue, ut morbi, eget eget"
  ]

  @user_names [
    "Mia Chapman",
    "Asuncion Cabrera",
    "Hélèna Roussel",
    "Noah Thomsen",
    "بهار قاسمی",
    "Ava Roberts",
    "Nicklas Madsen",
    "Genesis Perkins",
    "Konrad Janssen",
    "Volkan Poyrazoğlu",
    "Danielle Chapman",
    "Daniel Hernandez",
    "Eugene Chambers",
    "Arnaud Claire",
    "Cecilie Jensen",
    "Reginald Wheeler",
    "Taylor Fields",
    "Misael Teixeira",
    "Wendy Day",
    "Emma Bryant",
    "Christian Ortiz",
    "Emilio Saez",
    "Elise Jacob",
    "هستی نجاتی",
    "Leana Lefebvre",
    "Lya Robert",
    "Todd Byrd",
    "Ritthy Dunn",
    "Addison Harris",
    "Oskar Weber",
    "Alizee Giraud",
    "Victoria Soto",
    "Eemeli Kauppila",
    "Jordan Vidal",
    "سارینا احمدی",
    "Niklas Toro",
    "Deborah Thompson",
    "Jesus Harrison",
    "Lukas Bernard",
    "Elio Bertrand",
    "Lester Thomas",
    "Didaco Lopes",
    "Elisa Frank",
    "Alicja Hemmink",
    "Çetin Elmastaşoğlu",
    "Lloyd Garrett",
    "Ella Wright",
    "Neil Murray",
    "Joel Meyer",
    "Faustine Gerard"
  ]

  @phase_time_offsets [
    {0, 0},
    {0, 60},
    {60, 120}
  ]

  @urls [
    "url1"
  ]

  @candidate_summaries [
    """
    My main focus in the development of the Javascript language is a sane type system.
    Even though being a dynamic language shouldn't stop Javascript from helping the user prevent common mistakes.
    """,
    """
    As a Javascript poweruser, productivity is all that matters.
    It was fine for years until the influx of bootcamp graduates decided that JS hat to arrive in the twenty-first century.
    If your proposal fixes a bug, fine. We don't have to change the very core of the language just because we can.
    """,
    """
    In this age of web apps, javascript has become a de facto language for user interfaces. From this vantage point, it has to compete with the likes of Swift et al.
    Once you start writing both languages, it becomes apparent that javascript feels inferior. Its main disadvantage being the old and confusing prototypal inheritance system.

    I'm in favour of abolishing the prototype system and implementing a modern OOP approach from the bottom up.
    """,
    """
    One of the main trends in the Javascript eco-system has been the uptick of functional influences. React is among the most used and loved frameworks and borrows heavily from functional ideas.
    This is a healthy development and should be improved on. Even in the language itself.
    """,
    """
    15 Years Google Developer, Mountain View
    """,
    """
    I'm very passionate about Javascript.
    """
  ]

  def create_project do
    title = Enum.random(@titles)
    tickets = for _ <- 1..:rand.uniform(10), do: ticket()
    {phase_candidates, phase_end} = phases()

    attrs = %{
      title: title,
      tickets: tickets,
      phase_candidates: phase_candidates,
      phase_end: phase_end
    }

    {:ok, project} = Projects.create_project(attrs)
    project
  end

  def create_user do
    create_user(Enum.random(@user_names))
  end

  def create_user(name) do
    attrs = %{
      name: name
    }

    case Accounts.create_user(attrs) do
      {:ok, user} -> user
      {:error, _} -> create_user() # Dangerous, because once all usernames are used up, it ends in an endless loop
    end
  end

  def add_users_as_candidates_to_projects(users, projects) do
    for project <- projects,
        user <- users do
      Projects.add_candidate(project, user, Enum.random(@candidate_summaries))
    end
  end

  def add_users_as_users_to_projects(users, projects) do
    for project <- projects,
      user <- users do
        Projects.add_user(project, user)
    end
  end

  def create_proposal_projects do
    projects =
      for stage <- 1..3 do
        {candidates_offset, end_offset} = Enum.at(@phase_time_offsets, stage - 1)
        now = utc_now()
        %{
          title: "TC39 Proposals Stage #{stage}",
          tickets: proposal_tickets("stage#{stage}"),
          phase_candidates: add(now, candidates_offset * 60),
          phase_end: add(now, end_offset * 60)
        }
      end

    projects
    |> Enum.map(fn project_attrs ->
      {:ok, project} = Projects.create_project(project_attrs)
      project
    end)
  end

  def proposal_tickets(stage_key) do
    proposals()
    |> Map.get(stage_key)
    |> Enum.map(fn ticket ->
      %{
        title: Map.get(ticket, "title"),
        url: Map.get(ticket, "url")
      }
    end)
  end

  defp ticket do
    %{
      title: Enum.random(@titles),
      url: Enum.random(@urls)
    }
  end

  defp phases do
    {offset_candidates, offset_end} = Enum.random(@phase_time_offsets)
    now = utc_now()
    candidates_time = add(now, 60 * offset_candidates)
    end_time = add(now, 60 * offset_end)

    {candidates_time, end_time}
  end

  defp proposals do
    File.read!("./lib/ex_vote/seeds_tc39_proposals.json")
    |> Poison.decode!()
  end

end
