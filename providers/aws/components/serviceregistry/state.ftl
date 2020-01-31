[#ftl]

[#macro aws_serviceregistry_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local domainObject = getCertificateObject(solution.Namespace, segmentQualifiers)]
    [#local domainName = getCertificatePrimaryDomain(domainObject).Name ]

    [#assign componentState =
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
[/#macro]

[#macro aws_serviceregistryservice_cf_state occurrence parent={} ]
    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#local parentSolution = parent.Configuration.Solution ]
    [#local parentAttributes = parent.State.Attributes ]

    [#local serviceHostObject = mergeObjects(parentSolution.Namespace, solution.ServiceName) ]
    [#local domainObject = getCertificateObject( serviceHostObject, segmentQualifiers)]

    [#local serviceHost = getHostName(domainObject, occurrence)  ]
    [#local hostName = formatDomainName(serviceHost, parentAttributes["DOMAIN_NAME"] ) ]

    [#local serviceId = formatResourceId(AWS_CLOUDMAP_SERVICE_RESOURCE_TYPE, core.Id)]

    [#assign componentState =
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
[/#macro]
