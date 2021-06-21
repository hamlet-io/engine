# Hamlet Deploy - Engine

This is the Engine component of the Hamlet Deploy application. It contains core logic and internal data models, as well as the Shared provider.

See https://docs.hamlet.io for more info on Hamlet Deploy

## Installation

The engine is included as part of the official [hamlet base engine](https://github.com/hamlet-io/hamlet-engine-base/) so it will be included as part of your hamlet installation if you are using the [hamlet cli](https://pypi.org/project/hamlet-cli/)

### Alternative Methods

If you aren't using the hamlet cli or would like to contribute to the engine development the following local clone method is recommended

#### Local clone

Clone the repository locally to a path you know will stick around

```bash
git clone https://github.com/hamlet-io/engine.git
```

To manually perform an update on the Engine, simply pull down the latest changes using git.

```bash
cd ./path/to/engine
git pull
```

Set the following environment variable to tell the other hamlet parts with the engine is

| Name                  | Value              |
|-----------------------|--------------------|
| GENERATION_ENGINE_DIR | `<clone dir>`

### Usage

The Hamlet Deploy Engine cannot be invoked on its own and is reliant on other Hamlet Deploy components.

See https://docs.hamlet.io for more information.

### Contributing

When contributing to hamlet we recommend installing this plugin using the **Local Clone** method above using a fork of the repository

#### Testing

The plugin includes a test suite which generates a collection of deployments and checks that their content aligns with what is expected

To run the test suite locally install the hamlet cli and use the provider testing included

```bash

# install cli
pip install hamlet-cli

# run the tests
hamlet -p shared -p sharedtest -f default deploy run-deployments
```

This will run all of the tests and provide you the results. We also run this on all Pull requests made to the repository

##### Submitting Changes

Changes to the plugin are made through pull requests to this repo and all commits should use the [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/) format
This allows us to generate changelogs automatically and to understand what changes have been made
