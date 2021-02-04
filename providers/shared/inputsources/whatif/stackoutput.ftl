[#ftl]

[#macro shared_input_whatif_stackoutput_seed id="" deploymentUnit="" level="" region="" account=""]
    [@addStackOutputs getCFCompositeStackOutputs(id, deploymentUnit, level, region, account) /]
[/#macro]

[#macro shared_input_whatif_stackoutput id="" deploymentUnit="" level="" region="" account=""]

    [#local compositeOutput = getCFCompositeStackOutputs(id, deploymentUnit, level, region, account) ]
    [#if compositeOutput?has_content ]
        [@addStackOutputs compositeOutput /]
    [#else]
        [@addStackOutputs getSharedMockStackOutputs(id, deploymentUnit, level, region, account) /]
    [/#if]

[/#macro]
