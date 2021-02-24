# cfredirect Hamlet Extension

This is a Hamlet Deploy extension.

See docs.hamlet.io for more information.

## Description
<!-- provide a summary of the purpose and use-case for your extension -->
An AWS Lambda@Edge function used to send 301 redirections from any domains which are not the primary domain.

The header **_X-Redirect-Primary-Domain-Name_** defines the primary domain name where requests should be redirected.

## Provider
<!-- the associated Hamlet Plugin Provider required -->
`shared`

## Aliases
<!-- list any aliases that this Extension may be used as -->
- `_cfredirect-v1`

## Supported Types
<!-- List of component types that can be extended -->
- `lambda`
- `function`

## Entrances
<!-- List of entrances that this extension supports -->
- deployment