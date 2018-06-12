defmodule ExVoteWeb.Tokens do

  @salt "temporary static salt"
  @ttl 86400

  def sign(user_id) do
    Phoenix.Token.sign(ExVoteWeb.Endpoint, @salt, user_id)
  end

  def verify(token) do
    Phoenix.Token.verify(ExVoteWeb.Endpoint, @salt, token, max_age: @ttl)
  end

end
