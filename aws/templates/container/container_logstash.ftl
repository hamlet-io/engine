[#case "logstash"]
    [#assign esConfiguration = configurationObject.ElasticSearch]

    [@containerBasicAttributes
        name=containerName
        mode=containerListMode
        image="logstash" + dockerTag
    /]

    [@standardEnvironmentVariables
        containerListTarget containerListMode /]
        
    [@environmentVariable
        "LOGS" logsBucket
        containerListTarget containerListMode /]

    [@environmentVariable
        "REGION" regionId
        containerListTarget containerListMode /]

    [@environmentVariable
        "PRODUCT" productId
        containerListTarget containerListMode /]

    [@environmentVariable
        "CONTAINER" containerId
        containerListTarget containerListMode /]

    [@environmentVariable
        "ES" esConfiguration.EndPoint
        containerListTarget containerListMode /]

    [#if esConfiguration.MaximumIndexAge?has_content]
        [@environmentVariable
            "INDEX_AGE" esConfiguration.MaximumIndexAge
            containerListTarget containerListMode /]
    [/#if]
    
    [@containerVolume
            name="logstash"
            containerPath="/product/logstash"
            hostPath="/product/logstash" /]

    [@createPolicy
        mode=containerListMode
        id=containerListPolicyId
        name=containerListPolicyName
        statements=
            getS3ListBucketStatement(operationsBucket) +
            getS3ReadStatement(operationsBucket, "AWSLogs") +
            getS3ConsumeStatement(operationsBucket, "DOCKERLogs")
        roles=containerListRole
    /]

    [#break]
