#!/bin/sh

set -e
MIX_ENV=docker

sleep 5
mix ecto.create
mix ecto.reset
mix phx.server
