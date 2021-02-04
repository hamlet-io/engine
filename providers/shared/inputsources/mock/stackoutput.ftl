[#ftl]

[#-- Get stack output --]
[#macro shared_input_mock_stackoutput id="" deploymentUnit="" level="" region="" account=""]
    [@addStackOutputs getSharedMockStackOutputs(id, deploymentUnit, level, region, account) /]
[/#macro]
