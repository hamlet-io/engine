[#-- ELB --]

[#assign ELB_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "DNSName"
        }
    }
]
[#assign outputMappings +=
    {
        AWS_ELB_RESOURCE_TYPE : ELB_OUTPUT_MAPPINGS
    }
]
