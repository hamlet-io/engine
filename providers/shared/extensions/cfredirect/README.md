# cfredirect Hamlet Extension

This is a Hamlet Deploy extension.

See docs.hamlet.io for more information.

## Description
An AWS Lambda@Edge function used to send 301 redirections from any domains which are not the primary domain.

The header **_X-Redirect-Primary-Domain-Name_** defines the primary domain name where requests should be redirected.

## Provider
`shared`

## Aliases
- `_cfredirect-v1`

## Supported Types
- `lambda`
- `function`

## Entrances
- deployment
