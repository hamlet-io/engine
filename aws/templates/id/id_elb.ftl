[#-- ELB --]

[#-- Resources --]

[#assign ELB_RESOURCE_TYPE = "elb" ]

[#function formatELBId tier component extensions...]
    [#return formatComponentResourceId(
                ELB_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]
