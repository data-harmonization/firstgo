# myservice
A service to send messages to multiple channels (Mail, Slack, SMS and more)

# Local development

## Build
```
$ make
```

## DB and migrations
* Install local mysql / mariadb instance
* Bootstrap the service by calling:
```
$ make bootstrap
```

## Run
First run the AuthService: https://sbp.gitlab.schubergphilis.com/api/authservice
To run the MyService:
```
$ make run
```

## Unit tests
```
$ make test
```

## Integration tests (DB only)
- For integration tests you need a local instance of MySQL / MariaDB running locally.

To run integration tests:
```
$ make integration
```

## Integration tests (against other services)
- To run an integration test against authservice run:
```
$ make integration_docker
```

## Linting (run it before pushing)
```
$ make check
```

# Build pipeline
In the build pipeline the following command is used to build the service:
```
$ make release
```

When integrations tests are enabled for the pipeline the following command is used prior to the previous:
```
$ make integration_docker_jenkins
```
