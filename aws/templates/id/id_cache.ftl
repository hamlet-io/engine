[#-- ElastiCache --]

[#-- Resources --]

[#function formatCacheId tier component extensions...]
    [#return formatComponentResourceId(
                "cache",
                tier,
                component,
                extensions)]
[/#function]

[#function formatCacheSubnetGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "cacheSubnetGroup",
                tier,
                component,
                extensions)]
[/#function]

[#function formatCacheParameterGroupId tier component extensions...]
    [#return formatComponentResourceId(
                "cacheParameterGroup",
                tier,
                component,
                extensions)]
[/#function]

[#-- Attributes --]

[#function formatCacheDnsId resourceId]
    [#return formatDnsAttributeId(resourceId)]
[/#function]

[#function formatCachePortId resourceId]
    [#return formatPortAttributeId(resourceId)]
[/#function]

[#-- Outputs --]

[#macro outputMemcachedDns resourceId]
    [@outputAtt
        formatCacheDnsId(resourceId)
        resourceId
        "ConfigurationEndpoint.Address" /]
[/#macro]

[#macro outputMemcachedPort resourceId]
    [@outputAtt
        formatCachePortId(resourceId)
        resourceId
        "ConfigurationEndpoint.Port" /]
[/#macro]

[#macro outputRedisDns resourceId]
    [@outputAtt
        formatCacheDnsId(resourceId)
        resourceId
        "RedisEndpoint.Address" /]
[/#macro]

[#macro outputRedisPort resourceId]
    [@outputAtt
        formatCachePortId(resourceId)
        resourceId
        "RedisEndpoint.Port" /]
[/#macro]

