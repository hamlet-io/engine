[#ftl]

[#-- Get stack output --]
[#macro shared_input_mock_stackoutput id="" deploymentUnit="" level="" region="" account=""]
    [#switch id?split("X")?last ]
        [#case ARN_ATTRIBUTE_TYPE ]
            [#local value = "arn:aws:iam::123456789012:mock/" + id ]
            [#break]
        [#case URL_ATTRIBUTE_TYPE ]
            [#local value = "https://mock.local/" + id ]
            [#break]
        [#case IP_ADDRESS_ATTRIBUTE_TYPE ]
            [#local value = "123.123.123.123" ]
            [#break]
        [#case REGION_ATTRIBUTE_TYPE ]
            [#local value = "ap-mock-1" ]
            [#break]
        [#default]
            [#local value = formatId( "##MockOutput", id, "##") ]
    [/#switch]

    [@addStackOutputs 
        [
            {
                "Account" : account,
                "Region" : region,
                "Level" : level,
                "DeploymentUnit" : deploymentUnit,
                id : value
            }
        ]
    /]
[/#macro]
