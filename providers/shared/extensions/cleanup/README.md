# cleanup Hamlet Extension

This is a Hamlet Deploy extension.

See docs.hamlet.io for more information.

## Description
<!-- provide a summary of the purpose and use-case for your extension -->
A docker host cleaner. 

Removes containers and images older than the specified delay and period.

## Provider
<!-- the associated Hamlet Plugin Provider required -->
`shared`

## Aliases
<!-- list any aliases that this Extension may be used as -->
- `_cleanup`

## Supported Types
<!-- List of component types that can be extended -->
- `service`
- `containerservice`
- `task`
- `containertask`

## Entrances
<!-- List of entrances that this extension supports -->
- deployment