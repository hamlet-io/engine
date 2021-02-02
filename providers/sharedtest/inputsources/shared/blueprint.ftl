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
            }
        }
    /]
[/#macro]
