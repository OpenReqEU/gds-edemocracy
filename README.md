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

The API is documented via the OpenAPI v2 specification.

There are two documentation interfaces included at `/api/swagger` and `/api/redoc` respectivly:

- Swagger:
  Due to not supporting discriminator fields and markdown syntax, this endpoint should be seen as the "playground".
  Here you should test your requests and can view the response in the same interface.

- ReDoc:
  API documentation and data schemas can be found here.

## Seeded Data

By default, the application gets seeded with random projects, tickets and users.
There are three special accounts, which always get created:

  * Username: "guest"

    This account has no participation in any project.
  * Username: "user"

    This accounts has a participation of role "user" in every project.
  * Username: "candidate"

    See above only with the role "candidate"
