[#-- ElastiCache --]

[#assign REDIS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "RedisEndpoint.Address"
        },
        PORT_ATTRIBUTE_TYPE : { 
            "Attribute" : "RedisEndpoint.Port"
        }
    }
]
[#assign MEMCACHED_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "ConfigurationEndpoint.Address"
        },
        PORT_ATTRIBUTE_TYPE : { 
            "Attribute" : "ConfigurationEndpoint.Port"
        }
    }
]
[#assign outputMappings +=
    {
        AWS_CACHE_RESOURCE_TYPE : REDIS_OUTPUT_MAPPINGS
    }
]

[#assign metricAttributes +=
    {
        AWS_CACHE_RESOURCE_TYPE : {
            "Namespace" : "AWS/ElastiCache",
            "Dimensions" : {
                "CacheClusterId" : {
                    "Output" : "" 
                }
            }
        }
    }
]

