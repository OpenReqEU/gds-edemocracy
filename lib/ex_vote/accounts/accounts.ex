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
      %User{} ->
        changeset
      nil ->
        Ecto.Changeset.add_error(changeset, :name, "Username not found")
    end
  end

  def delete_user(user_id) do
    user = %User{id: user_id}
    Repo.delete(user)
  end

  # @moduledoc """
  # The Accounts context.
  # """

  # import Ecto.Query, warn: false
  # alias ExVote.Repo

  # alias ExVote.Accounts.User

  # @doc """
  # Returns the list of users.

  # ## Examples

  #     iex> list_users()
  #     [%User{}, ...]

  # """
  # def list_users do
  #   Repo.all(User)
  # end

  # @doc """
  # Gets a single user.

  # Raises `Ecto.NoResultsError` if the User does not exist.

  # ## Examples

  #     iex> get_user!(123)
  #     %User{}

  #     iex> get_user!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_user!(id), do: Repo.get!(User, id)

  # @doc """
  # Creates a user.

  # ## Examples

  #     iex> create_user(%{field: value})
  #     {:ok, %User{}}

  #     iex> create_user(%{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def create_user(attrs \\ %{}) do
  #   %User{}
  #   |> User.changeset(attrs)
  #   |> Repo.insert()
  # end

  # @doc """
  # Updates a user.

  # ## Examples

  #     iex> update_user(user, %{field: new_value})
  #     {:ok, %User{}}

  #     iex> update_user(user, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_user(%User{} = user, attrs) do
  #   user
  #   |> User.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a User.

  # ## Examples

  #     iex> delete_user(user)
  #     {:ok, %User{}}

  #     iex> delete_user(user)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_user(%User{} = user) do
  #   Repo.delete(user)
  # end

  # @doc """
  # Returns an `%Ecto.Changeset{}` for tracking user changes.

  # ## Examples

  #     iex> change_user(user)
  #     %Ecto.Changeset{source: %User{}}

  # """
  # def change_user(%User{} = user) do
  #   User.changeset(user, %{})
  # end
end
