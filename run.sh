#!/bin/sh

set -e
sleep 5
mix ecto.create
mix ecto.migrate
mix phx.server
