[#case "logstash"]
[#case "_logstash"]

    [#assign esConfiguration = configurationObject.ElasticSearch]

    [@Attributes name="logstash" /]

    [@Variables
        {
            "LOGS" : logsBucket,
            "REGION" : regionId,
            "PRODUCT" : productId,
            "CONTAINER" : containerId,
            "ES" : esConfiguration.EndPoint
        }
    /]
    
    [#if esConfiguration.MaximumIndexAge?has_content]
        [@Variable "INDEX_AGE" esConfiguration.MaximumIndexAge /]
    [/#if]
    
    [@Volume "logstash" "/product/logstash" "/product/logstash" /]

    [@Policy
        s3ListBucketPermission(operationsBucket) +
        s3ReadPermission(operationsBucket, "AWSLogs") +
        s3ConsumePermission(operationsBucket, "DOCKERLogs")
    /]

    [#break]

