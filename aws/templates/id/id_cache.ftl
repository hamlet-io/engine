[#-- ElastiCache --]

[#assign CACHE_RESOURCE_TYPE = "cache" ]

[#function formatCacheId tier component extensions...]
    [#return formatComponentResourceId(
                CACHE_RESOURCE_TYPE,
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
