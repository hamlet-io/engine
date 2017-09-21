[#-- RDS --]

[#assign RDS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "Endpoint.Address"
        },
        PORT_ATTRIBUTE_TYPE : { 
            "Attribute" : "Endpoint.Port"
        }
    }
]
[#assign outputMappings +=
    {
        RDS_RESOURCE_TYPE : RDS_OUTPUT_MAPPINGS
    }
]

