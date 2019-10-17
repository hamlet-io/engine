[#ftl]

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
        },
        REGION_ATTRIBUTE_TYPE: {
            "Value" : { "Ref" : "AWS::Region" }
        }
    }
]

[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_ES_RESOURCE_TYPE
    mappings=ES_OUTPUT_MAPPINGS
/]

[#assign metricAttributes +=
    {
        AWS_ES_RESOURCE_TYPE : {
            "Namespace" : "AWS/ES",
            "Dimensions" : {
                "DomainName" : {
                    "Output" : ""
                },
                "ClientId" : {
                    "PseudoOutput" : "AWS::AccountId"
                }
            }
        }
    }
]

[#function formatESDomainArn esId indexPath=["*"] region={ "Ref" : "AWS::Region" } account={ "Ref" : "AWS::AccountId" } ]
    [#return
        formatRegionalArn(
            "es",
            formatTypedArnResource(
                "domain"
                getReference(esId),
                "/",
                indexPath
            ) ,
            region,
            account
        )
    ]
[/#function]