FROM elixir:alpine
WORKDIR /ex_vote
COPY . /ex_vote

ENV MIX_ENV=docker

RUN mix local.hex --force
RUN HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=120 mix deps.get
RUN mix local.rebar --force
#RUN mix deps.get
RUN mix deps.compile
RUN mix compile

EXPOSE 4000
CMD ["./run.sh"]