[#-- Cloud Map Resources --]


[#assign CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        }
    }
]

[#assign CLOUDMAP_SERVICE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "Attribute" : "Arn"
        },
        NAME_ATTRIBUTE_TYPE : {
            "Attribute" : "Name"
        }
    }
]

[#assign outputMappings +=
    {
        AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE : CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS,
        AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE : CLOUDMAP_SERVICE_OUTPUT_MAPPINGS
    }
]

[#macro createCloudMapDNSNamespace 
    mode id name 
    domainName
    public
    vpcId=""
    dependencies=""
]
    
    [#if public ]
        [@cfResource 
            mode=mode
            id=id
            type="AWS::ServiceDiscovery::PublicDnsNamespace"
            properties=
                {
                    "Description" : name
                    "Name" : domainName
                }
            outputs=CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS
            dependencies=dependencies
        /]
    [#else]
        [@cfResource 
            mode=mode
            id=id
            type="AWS::ServiceDiscovery::PrivateDnsNamespace"
            properties=
                {
                    "Description" : name
                    "Name" : domainName,
                    "Vpc" : getReference(vpcId)
                }
            outputs=CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS
            dependencies=dependencies
        /]
    [/#if]
[/#macro]

[#macro createCloudMapService
    mode id name
    namespaceId
    hostName
    routingPolicy
    recordTypes
    recordTTL
    dependencies=""
]

    [#local dnsRecords = [] ]
    [#list recordTypes as recordType ]
        [#assign dnsRecords += 
            [ 
                {
                    "TTL" : recordTTL?c,
                    "Type" : recordType?upper_case
                }
            ]]
    [/#list]
    

    [#switch routingPolicy?upper_case ]
        [#case "ALLATONCE" ]
        [#case "MULTIVALUE" ]
            [#local routingPolicy = "MULTIVALUE" ]
            [#break]
        
        [#case "ONLYONE" ]
        [#csae "WEIGHTED" ]
            [#local routingPolicy = "WEIGHTED" ]
            [#break]
    [/#switch]

    [@cfResource 
        mode=mode
        id=id
        type="AWS::ServiceDiscovery::Service"
        properties=
            {
                "Description" : name,
                "DnsConfig" : {
                    "DnsRecords" : dnsRecords,
                    "NamespaceId" : getReference(namespaceId),
                    "RoutingPolicy" : routingPolicy
                },
                "Name" : hostName,
                "NamespaceId" : getReference(namespaceId)
            }
        outputs=CLOUDMAP_SERVICE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]



