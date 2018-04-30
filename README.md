# ExVote

**This is an early prototype!**

## Installation

Prerequisites:

  * Docker
  * Docker Compose

Download or clone this repository, change into its directory and build the image by running

```
docker-compose build
```

Once this process finishes you can now start the application via

```
docker-compose up
```

Navigate to http://localhost:4000 to view the application.

## API

The API is documented via the OpenAPI specification. There is a Swagger webinterface included at http://localhost:4000/api/swagger

## Seeded Data

By default, the application gets seeded with random projects, tickets and users.
There are three special accounts, which always get created:

  * Username: "guest"

    This account has no participation in any project.
  * Username: "user"

    This accounts has a participation of role "user" in every project.
  * Username: "candidate"

    See above only with the role "candidate"
