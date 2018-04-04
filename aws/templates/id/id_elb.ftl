[#-- ELB --]

[#-- Resources --]

[#assign AWS_ELB_RESOURCE_TYPE = "elb" ]

[#function formatELBId tier component extensions...]
    [#return formatComponentResourceId(
                AWS_ELB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]
