[#ftl]

[#-- Get stack output --]
[#macro shared_input_mock_stackoutput id="" deploymentUnit="" level="" region="" account=""]
    [@addStackOutputs 
        [
            {
                "Account" : account,
                "Region" : region,
                "Level" : level,
                "DeploymentUnit" : deploymentUnit,
                id : DEFAULT_STACKOUTPUT_MOCK_VALUE
            }
        ]
    /]
[/#macro]
