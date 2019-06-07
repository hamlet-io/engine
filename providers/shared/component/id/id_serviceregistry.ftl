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
                    "Type" : SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE,
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

[#macro aws_serviceregistry_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getServiceRegistryState(occurrence)]
[/#macro]

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
