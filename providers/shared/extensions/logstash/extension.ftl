[#ftl]

[@addExtension
    id="logstash"
    aliases=[
        "_logstash"
    ]
    description=[
        "Basic elasticsearch logstash deployment"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_logstash_deployment_setup occurrence ]

    [#local esLinkId = (_context.DefaultEnvironment["ES_LINK_ID"])!"es" ]
    [#local esLink = _context.Links[esLinkId]]
    [#local esFQDN = esLink.State.Attributes["FQDN"]]
    [#local esPort = esLink.State.Attributes["PORT"]]

    [#local baselineLinks = getBaselineLinks(occurrence, [ "OpsData"] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [@Attributes name="logstash" /]

    [@Variables
        {
            "LOGS" : logsBucket,
            "REGION" : getRegion(),
            "PRODUCT" : productId,
            "CONTAINER" : fragmentId,
            "ES" : esFQDN + ":" + esPort
        }
    /]

    [#if esConfiguration.MaximumIndexAge?has_content]
        [@Variable "INDEX_AGE" esConfiguration.MaximumIndexAge /]
    [/#if]

    [@Volume "logstash" "/product/logstash" "/product/logstash" /]

    [@Policy
        s3ListBucketPermission(baselineComponentIds["OpsData"]) +
        s3ReadPermission(baselineComponentIds["OpsData"], "AWSLogs") +
        s3ConsumePermission(baselineComponentIds["OpsData"], "DOCKERLogs")
    /]

[/#macro]
