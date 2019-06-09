[#ftl]
[#macro aws_serviceregistry_cf_solution occurrence ]
    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core ]
    [#local solution = occurrence.Configuration.Solution ]
    [#local resources = occurrence.State.Resources ]

    [#local registryId = resources["namespace"].Id ]
    [#local registryName = resources["namespace"].Name ]
    [#local registryDnsDomain = resources["namespace"].DomainName ]

    [#-- Network lookup --]
    [#local networkLink = tier.Network.Link!{} ]
    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]
    [#local vpcId = networkResources["vpc"].Id ]
    [#local routeTableLinkTarget = getLinkTarget(occurrence, networkLink + { "RouteTable" : tier.Network.RouteTable })]
    [#local routeTableConfiguration = routeTableLinkTarget.Configuration.Solution ]
    [#local publicRouteTable = routeTableConfiguration.Public ]

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

        [#local core = subOccurrence.Core ]
        [#local solution = subOccurrence.Configuration.Solution ]
        [#local resources = subOccurrence.State.Resources ]

        [#local serviceId = resources["service"].Id]
        [#local serviceName = resources["service"].Name]
        [#local serviceHostName = resources["service"].ServiceName ]

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
[/#macro]