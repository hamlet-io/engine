[#ftl]

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
        }
    }
]

[#assign CLOUDMAP_INSTANCE_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        }
    }
]

[#assign cloudmapMappings =
    {
        AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE : CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS,
        AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE : CLOUDMAP_SERVICE_OUTPUT_MAPPINGS,
        AWS_CLOUDMAP_INSTANCE_RESOURCE_TYPE : CLOUDMAP_INSTANCE_OUTPUT_MAPPINGS
    }
]

[#list cloudmapMappings as type, mappings]
    [@addOutputMapping 
        provider=AWS_PROVIDER
        resourceType=type
        mappings=mappings
    /]
[/#list]

[#macro createCloudMapDNSNamespace
    id name
    domainName
    public
    vpcId=""
    dependencies=""
]

    [#if public ]
        [@cfResource
            id=id
            type="AWS::ServiceDiscovery::PublicDnsNamespace"
            properties=
                {
                    "Description" : name,
                    "Name" : domainName
                }
            outputs=CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS
            dependencies=dependencies
        /]
    [#else]
        [@cfResource
            id=id
            type="AWS::ServiceDiscovery::PrivateDnsNamespace"
            properties=
                {
                    "Description" : name,
                    "Name" : domainName,
                    "Vpc" : getReference(vpcId)
                }
            outputs=CLOUDMAP_DNS_NAMESPACE_OUTPUT_MAPPINGS
            dependencies=dependencies
        /]
    [/#if]
[/#macro]

[#macro createCloudMapService
    id name
    namespaceId
    hostName
    routingPolicy
    recordTypes
    recordTTL
    dependencies=""
]

    [#local dnsRecords = [] ]

    [#list recordTypes as recordType ]
        [#local dnsRecords +=
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
        [#case "WEIGHTED" ]
            [#local routingPolicy = "WEIGHTED" ]
            [#break]
    [/#switch]

    [#if recordTypes?seq_contains("CNAME") ]
        [#if !(routingPolicy == "WEIGHTED") ]
           [@fatal
                message="CNAME records are only supported for WEIGHTED Routing policy"
                context=occurrence
            /]
        [/#if]

        [#if recordTypes?size > 1 ]
            [@fatal
                message="CNAME record types can not be used with other record types"
                context=occurrence
            /]
        [/#if]
    [/#if]

    [@cfResource
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
                "NamespaceId" : getReference(namespaceId),
                "HealthCheckCustomConfig" : {
                    "FailureThreshold" : 1
                }
            }
        outputs=CLOUDMAP_SERVICE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

[#function getCloudMapInstanceAttribute type value ]
    [#switch type ]
        [#case "alias" ]
            [#local type = "AWS_ALIAS_DNS_NAME" ]
            [#break]
        [#case "cname" ]
            [#local type = "AWS_INSTANCE_CNAME" ]
            [#break]
        [#case "ipv4" ]
            [#local type = "AWS_INSTANCE_IPV4" ]
            [#break]
        [#case "ipv6" ]
            [#local type = "AWS_INSTANCE_IPV6" ]
            [#break]
        [#case "port" ]
            [#local type = "AWS_INSTANCE_PORT" ]
            [#break]
        [#default]
            [@fatal
                message="invalid attribute type"
                context=type
            /]
    [/#switch]

    [#return { type : value }]
[/#function]

[#macro createCloudMapInstance
    id
    serviceId
    instanceId
    instanceAttributes
    dependencies=""
]

    [@cfResource
        id=id
        type="AWS::ServiceDiscovery::Instance"
        properties=
            {
                "InstanceAttributes": instanceAttributes,
                "ServiceId": getReference(serviceId),
                "InstanceId" : instanceId
            }
        outputs=CLOUDMAP_INSTANCE_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]

