[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro sharedtest_input_shared_blueprint_seed ]
    [@addBlueprint
        blueprint={
            "Solution" : {
                "Modules" : {
                    "internaltest" : {
                        "Provider" : "sharedtest",
                        "Name" : "internaltest"
                    }
                }
            },
            "PlacementProfiles": {
                "internal": {
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
