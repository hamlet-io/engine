[#-- Resources --]
[#assign AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE = "cloudmapdnsnamespace" ]
[#assign AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE = "cloudmapservice" ]
[#assign AWS_CLOUDMAP_INSTANCE_RESOURCE_TYPE = "cloudmapinstance" ]

[#-- Components --]
[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign componentConfiguration +=
    {
        SERVICE_REGISTRY_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "DNS based service registry"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "Namespace",
                    "Children" : domainNameChildConfiguration
                }
            ],
            "Components" : [
                {
                    "Type" : REGISTRY_SERVICE_COMPONENT_TYPE,
                    "Component" : "RegistryServices",
                    "Link" : ["RegistryService" ]
                }
            ]
        },
        SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE : {
            "Properties"  : [
                {
                    "Type"  : "Description",
                    "Value" : "An individual service in the registry"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                },
                {
                    "Names" : "Links",
                    "Subobjects" : true,
                    "Children" : linkChildrenConfiguration
                },
                {
                    "Names" : "ServiceName",
                    "Description" : "The hostname portion of the DNS record which will identify this service",
                    "Children" : hostNameChildConfiguration
                },
                {
                    "Names" : "RecordTypes",
                    "Description" : "The types of DNS records that an instance can register with the service",
                    "Type" : ARRAY_OF_STRING_TYPE,
                    "Values" : [ "A", "AAAA", "CNAME", "SRV" ],
                    "Default" : [ "A" ]
                },
                {
                    "Names" : "RecordTTL",
                    "Description" : "DNS record TTL ( in seconds)",
                    "Type" : NUMBER_TYPE,
                    "Default" : 300
                },
                {
                    "Names" : "RoutingPolicy",
                    "Description" : "How the service returns records to the client",
                    "Values" : [ "AllAtOnce", "OnlyOne" ],
                    "Type" : STRING_TYPE,
                    "Default" : "OnlyOne"
                }
            ]
        }
    }]

[#function getServiceRegistryState occurrence ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local domainObject = getCertificateObject(solution.Namespace, segmentQualifiers)]
    [#local domainName = getCertificatePrimaryDomain(domainObject).Name ]

    [#return
        {
            "Resources" : {
                "namespace" : {
                    "Id" : formatResourceId(AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE, core.Id),
                    "Name" : core.FullName,
                    "DomainName" : domainName,
                    "Type" : AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE
                }
            }, 
            "Attributes" : {
                "DOMAIN_NAME" : domainName
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]


[#function getServiceRegistryServiceState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentAttributes = parent.State.Attributes ]

    [#local serviceHostObject = mergeObjects(parentSolution.Namespace, solution.ServiceName) ]
    [#local domainObject = getCertificateObject( serviceHostObject, segmentQualifiers)]

    [#local serviceHost = getHostName(domainObject, occurrence)  ]
    [#local hostName = formatDomainName(serviceHost, parentAttributes["DOMAIN_NAME"] ) ]

    [#assign serviceId = formatResourceId(AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE, core.Id, hostName)]

    [#return
        {
            "Resources" : {
                "service" : {
                    "Id" : serviceId,
                    "Name" : core.FullName,
                    "ServiceName" : serviceHost,
                    "Type" : AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE
                }
            }, 
            "Attributes" : {
                "FQDN" : hostName,
                "RECORD_TYPES" : solution.RecordTypes?join(","),
                "SERVICE_ARN" : getExistingReference(serviceId, ARN_ATTRIBUTE_TYPE)
            },
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        }
    ]
[/#function]
