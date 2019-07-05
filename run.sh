#!/bin/sh

set -e
MIX_ENV=docker

rm -rf ./_build
mix compile
sleep 5
#mix ecto.drop
mix ecto.create
mix ecto.migrate
#mix run priv/repo/seeds.exs
mix phx.server
