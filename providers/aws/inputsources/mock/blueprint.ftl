[#ftl]

[#-- Intial seeding of settings data based on input data --]
[#macro aws_input_mock_blueprint_seed ]
    [@addBlueprint
        blueprint=
        {
            "Account": {
                "Region": "ap-southeast-2",
                "AWSId": "0123456789"
            },
            "Product": {
                "Region": "ap-southeast-2"
            }
        }
    /]
[/#macro]