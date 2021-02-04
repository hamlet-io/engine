[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro sharedtest_input_shared_blueprint_seed ]
    [@addBlueprint
        blueprint={
            "Solution" : {
                "Modules" : {
                    "externalservice" : {
                        "Provider" : "sharedtest",
                        "Name" : "externalservice"
                    }
                }
            },
            "PlacementProfiles": {
                "external": {
                    "default": {
                        "Provider": "sharedtest",
                        "Region": "external",
                        "DeploymentFramework": "default"
                    }
                }
            }
        }
    /]
[/#macro]
