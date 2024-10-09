# MeteoSense

MeteoSense is a weater forcasting service based on the entered address.

## Run project

```bash
docker-compose up --build
```

Visit http://localhost:3000.

## How it's configured

Docker compose starts following contianers:

- api (Ruby on Rails)
- ui (React)
- redis
- nginx

Every request is hittin nginx first, then based on the path patterns the requests will be redirected to the right container. The redirects configured based on the following rules:

- paths starting with `/api` is routed to the `api` container
- everything else is redirected to the `ui` contianer
- requests with paths starting with `/ws` are treated separately and serve only to support hot reload on the frontend side in the development environment

Nginx can serve as a load balancer if more servers specified.

## CI

The basic UI and API checks (tests, linters and vulnerability scans) are implemented using GitHub Actions.
