# dind Hamlet Extension

This is a Hamlet Deploy extension.

See docs.hamlet.io for more information.

## Description
<!-- provide a summary of the purpose and use-case for your extension -->
Docker-in-docker (DIND).

Provides access to a docker-in-docker container configured with its own dedicated storage volumes provisioned on demand.

Generates a TLS certificate which an be shared with other containers as a part of a `task` or `service`.

## Provider
<!-- the associated Hamlet Plugin Provider required -->
`shared`

## Aliases
<!-- list any aliases that this Extension may be used as -->
- `_dind`

## Supported Types
<!-- List of component types that can be extended -->
- `service`
- `containerservice`
- `task`
- `containertask`

## Entrances
<!-- List of entrances that this extension supports -->
- deployment