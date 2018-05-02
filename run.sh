#!/bin/sh

set -e
sleep 5
mix ecto.create
mix ecto.reset
mix run priv/repo/seeds.exs
mix phx.server
