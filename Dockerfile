FROM elixir:1.8.1-alpine
WORKDIR /ex_vote
COPY . /ex_vote

ENV MIX_ENV=docker
RUN mix local.hex --force
# RUN mix deps.get
RUN HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix deps.get
RUN mix local.rebar --force
RUN mix deps.compile

EXPOSE 9750
CMD ["./run.sh"]
