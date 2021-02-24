# dind Hamlet Extension

This is a Hamlet Deploy extension.

See docs.hamlet.io for more information.

## Description
Docker-in-docker (DIND).

Provides access to a docker-in-docker container configured with its own dedicated storage volumes provisioned on demand.

Generates a TLS certificate which an be shared with other containers as a part of a `task` or `service`.

## Provider
`shared`

## Aliases
- `_dind`

## Supported Types
- `service`
- `containerservice`
- `task`
- `containertask`

## Entrances
- deployment
