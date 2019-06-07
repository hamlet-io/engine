[#-- Resources --]
[#assign AWS_CLOUDMAP_DNS_NAMESPACE_RESOURCE_TYPE = "cloudmapdnsnamespace" ]
[#assign AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE = "cloudmapservice" ]
[#assign AWS_CLOUDMAP_INSTANCE_RESOURCE_TYPE = "cloudmapinstance" ]

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

[#macro aws_serviceregistryservice_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getServiceRegistryServiceState(occurrence, parent)]
[/#macro]

[#function getServiceRegistryServiceState occurrence parent ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentAttributes = parent.State.Attributes ]

    [#local serviceHostObject = mergeObjects(parentSolution.Namespace, solution.ServiceName) ]
    [#local domainObject = getCertificateObject( serviceHostObject, segmentQualifiers)]

    [#local serviceHost = getHostName(domainObject, occurrence)  ]
    [#local hostName = formatDomainName(serviceHost, parentAttributes["DOMAIN_NAME"] ) ]

    [#assign serviceId = formatResourceId(AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE, core.Id)]

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
