[#-- ElasticSearch --]

[#-- Resources --]

[#function formatElasticSearchId tier component extensions...]
    [#return formatComponentResourceId(
                "es",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatElasticSearchDnsId resourceId]
    [#return formatDnsAttributeId(resourceId)]
[/#function]

[#-- Outputs --]

[#macro outputElasticSearchArn resourceId]
    [@outputAtt
        formatArnAttributeId(resourceId)
        resourceId
        "DomainArn" /]
[/#macro]

[#macro outputElasticSearchUrl resourceId]
    [@outputAtt
        formatDnsAttributeId(resourceId)
        resourceId
        "DomainEndpoint" /]
[/#macro]


