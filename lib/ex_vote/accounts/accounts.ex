defmodule ExVote.Accounts do
  import Ecto.Query

  alias ExVote.Repo
  alias ExVote.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_user(user_id) do
    Repo.get(User, user_id)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset_create(attrs)
    |> Repo.insert()
  end

  def find_user(name) do
    query = from u in User,
      where: u.name == ^name

    Repo.one(query)
  end

  def login(attrs \\ %{}) do
    %User{}
    |> User.changeset_create(attrs) # TODO: Create changeset_login
    |> check_login()
    |> Ecto.Changeset.apply_action(:insert)
  end

  defp check_login(%{:valid? => false} = changeset), do: changeset

  defp check_login(%{:valid? => true} = changeset) do
    username = Ecto.Changeset.get_field(changeset, :name)

    query = from u in User,
      where: u.name == ^username

    case Repo.one(query) do
      %User{:id => id} ->
        changeset
        |> Ecto.Changeset.put_change(:id, id)
      nil ->
        changeset
        |> Ecto.Changeset.add_error(:name, "Username not found")
    end
  end

  def delete_user(user_id) do
    user = %User{id: user_id}
    Repo.delete(user)
  end
end
