# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExVote.Repo.insert!(%ExVote.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import ExVote.Seeder

users = for _ <- 1..20, do: create_user()
projects = for _ <- 1..30, do: create_project()

guest = create_user("guest")
user = create_user("user")
candidate = create_user("candidate")

users = [candidate | users]

add_users_as_candidates_to_projects(users, projects)
add_users_as_users_to_projects([user], projects)
