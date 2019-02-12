
## Liquid Democracy for OpenReq

![EPL 2.0](https://img.shields.io/badge/License-EPL%202.0-blue.svg "EPL 2.0")

This component was created as a result of the OpenReq project funded by the European Union Horizon 2020 Research and Innovation programme under grant agreement No 732463.

## Technical Description
This microservice exposes several endpoints to manage a liquid democracy election process through delegate voting.
A simple web-based UI is provided to check the current status of the election process and its outcome.

The component provides seed data to show an example of liquid democracy election process. However, using the API it is possible to hook the component into third-party sources (e.g., Bugzilla, GitHub Issues). These resources (e.g., a bug in Bugzilla) represent the items that can be voted for inclusion in a release or prioritization.

## Technologies used

For app development:
 * Elixir
 * Phoenix

For virtualization:
 * Docker
 * Docker Compose

 ## How to install

Download or clone this repository, change into its directory and build the image by running

```
docker-compose build
```

Once this process finishes, you can now start the application via

```
docker-compose up
```

Navigate to http://localhost:4000 to view the application.

## How to use

The API is documented via the OpenAPI v2 specification.

The Swagger documentation interface can be found under `/api/swagger`

The Swagger specification is generated by running the following command:

  ```
  mix phx.swagger.generate
  ```

Notice, Swagger does not support discriminator fields use to display the current phase of the voting process.

A Swagger playground is accessible at [api.openreq.eu](api.openreq.eu)

### Seeded Data

By default, the application gets seeded with random projects, tickets and users.
There are three special accounts:

* Username "guest": This account does not actively participate in any voting.
* Username: "user": This account participate as a voting user in every voting.
* Username: "candidate": This account participate as a candidate (i.e., can vote for items) in every voting.

## Note for developers
1. Clone and cd into the repository
2. Make sure PostgreSQL is running
3. `mix get.deps` to download the dependencies
4. Modify `priv/repo/seed.exs` to change the database seeds (if necessary)
5. `mix ecto.create && mix ecto.migrate` to seed the database
6. `mix phx.server` to start the app
7. `mix test` to run unit tests

Notice that when run using Docker, the configuration already includes a dependency for PostgreSQL database (see `docker-compose.yml`).
Please, modify `config/dev.exs` or `config/docker.exs` depending on how you run the application (in local development or using docker).
To run the application in production, please create and populate the file `config/prod.exs`.

## References
- Johann Timo and Maalej Walid _Liquid Democracy for a Sustainable and Scalable Participation in Requirements Engineering._
Requirements Engineering for Sustainability workshop at Requirements Engineering conference, 2014.

## How to contribute

See OpenReq project contribution
[Contribution Guidelines](https://github.com/OpenReqEU/OpenReq/blob/master/CONTRIBUTING.md).


## License

Free use of this software is granted under the terms of the EPL version 2 ([EPL2.0](https://www.eclipse.org/legal/epl-2.0/)).
