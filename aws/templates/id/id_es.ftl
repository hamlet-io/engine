[#-- ElasticSearch --]

[#assign ES_RESOURCE_TYPE = "es" ]

[#function formatElasticSearchId tier component extensions...]
    [#return formatComponentResourceId(
                ES_RESOURCE_TYPE,
                tier,
                component,
                extensions)]
[/#function]
