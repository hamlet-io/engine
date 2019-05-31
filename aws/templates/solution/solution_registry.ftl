[#ftl]
[#macro aws_serviceregistry_cf_solution occurrence]
    [@cfDebug listMode occurrence false /]

    [#assign core = occurrence.Core ]
    [#assign solution = occurrence.Configuration.Solution ]
    [#assign resources = occurrence.State.Resources ]

    [#assign registryId = resources["namespace"].Id ]
    [#assign registryName = resources["namespace"].Name ]
    [#assign registryDnsDomain = resources["namespace"].DomainName ]

    [#-- Network lookup --]
    [#assign networkLink = tier.Network.Link!{} ]
    [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#assign networkResources = networkLinkTarget.State.Resources ]
    [#assign vpcId = networkResources["vpc"].Id ]
    [#assign routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : tier.Network.RouteTable })]
    [#assign routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#assign publicRouteTable = routeTableConfiguration.Public ]

    [#if deploymentSubsetRequired(SERVICE_REGISTRY_COMPONENT_TYPE, true) ]
        [@createCloudMapDNSNamespace
            mode=listMode
            id=registryId
            name=registryName
            domainName=registryDnsDomain
            public=publicRouteTable
            vpcId=vpcId
        /]
    [/#if]

    [#list occurrence.Occurrences![] as subOccurrence]

        [#assign core = subOccurrence.Core ]
        [#assign solution = subOccurrence.Configuration.Solution ]
        [#assign resources = subOccurrence.State.Resources ]

        [#assign serviceId = resources["service"].Id]
        [#assign serviceName = resources["service"].Name]
        [#assign serviceHostName = resources["service"].ServiceName ]

        [#if deploymentSubsetRequired(SERVICE_REGISTRY_COMPONENT_TYPE, true) ]
            [@createCloudMapService
                mode=listMode
                id=serviceId
                name=serviceName
                namespaceId=registryId
                hostName=serviceHostName
                routingPolicy=solution.RoutingPolicy
                recordTypes=solution.RecordTypes
                recordTTL=solution.RecordTTL
                dependencies=registryId
            /]
        [/#if]
    [/#list]
[/#if]