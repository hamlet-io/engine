[#-- ELB --]

[#-- Resources --]

[#function formatELBId tier component extensions...]
    [#return formatComponentResourceId(
                "elb",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]
