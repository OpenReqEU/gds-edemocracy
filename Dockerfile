FROM elixir:alpine
WORKDIR /ex_vote
COPY . /ex_vote

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

EXPOSE 4000
CMD ["./run.sh"]