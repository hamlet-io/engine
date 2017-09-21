[#-- ElasticSearch --]

[#assign ES_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "DomainArn"
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "DomainEndpoint"
        }
    }
]
[#assign outputMappings +=
    {
        ES_RESOURCE_TYPE : ES_OUTPUT_MAPPINGS
    }
]

