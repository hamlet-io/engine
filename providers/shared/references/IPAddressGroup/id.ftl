[#ftl]

[@addReference
    type=IPADDRESSGROUP_REFERENCE_TYPE
    pluralType="IPAddressGroups"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A collection of CIDR based IP Addresses used for access control"
            }
        ]
    attributes=[
        {
            "Names" : "CIDR",
            "Types" : ARRAY_OF_STRING_TYPE
        },
        {
            "Names" : "Description",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "IsOpen",
            "Types" : BOOLEAN_TYPE
        }
    ]
/]


[#-- Filter out open cidrs --]
[#function getEffectiveIPAddressGroup group]
    [#-- Support manually forcing group to always be considered open --]
    [#local groupIsOpen = false ]
    [#local cidrs = [] ]

    [#if group.Enabled!true]
        [#local groupIsOpen = group.IsOpen!groupIsOpen ]

        [#list group as key,value]
            [#if value?is_hash && value.Enabled!true]
                [#local isOpen = (value.IsOpen)!false ]
                [#list asFlattenedArray(value.CIDR![]) as cidrEntry ]
                    [#if cidrEntry == "0.0.0.0" || cidrEntry == "0.0.0.0/0" ]
                        [#local isOpen = true]
                    [#else]
                        [#local cidrs += [cidrEntry] ]
                    [/#if]
                [/#list]
                [#local groupIsOpen = groupIsOpen || isOpen ]
            [/#if]
        [/#list]
    [/#if]
    [#return
        {
            "Id" : group.Id,
            "Name" : group.Name,
            "IsOpen" : groupIsOpen,
            "CIDR" : valueIfTrue([], groupIsOpen, cidrs)
        } ]
[/#function]

[#function getEffectiveIPAddressGroups groups]
    [#local result = {} ]
    [#list groups as key,value]
        [#if value?is_hash]
            [#local result +=
                {
                    key :
                        getEffectiveIPAddressGroup(
                            addIdNameToObject(value, key)
                        )
                } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getIPAddressGroup group occurrence={}]
    [#local groupId = group?is_hash?then(group.Id, group) ]

    [#if groupId?starts_with("_named") || groupId?starts_with("__named") ]
        [#local lookupName = groupId?split(":")[1]]
        [#if ! lookupName?has_content]
            [@fatal
                message="Invalid named IP address group"
                detail="Provide named groups as _named: name of group"
                context=groupId
            /]

            [#return
                {
                    "Id" : groupId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : []
                }
            /]
        [/#if]
        [#local groupDetailId = groupId ]
        [#local groupId = "_named" ]
    [/#if]

    [#if groupId?starts_with("_tier") || groupId?starts_with("__tier") ]
        [#local lookupTier = groupId?split(":")[1] ]
        [#local lookupZone = (groupId?split(":")[2])!"" ]
        [#if ! lookupTier?has_content ]
            [@fatal
                message="Invalid Tier IP AddressGroup"
                detail="Please provide tier groups as _tier:tierId"
                context=groupId
            /]

            [#return
                {
                    "Id" : groupId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : []
                }]
        [/#if]
        [#local groupDetailId = groupId ]
        [#local groupId = "_tier" ]
    [/#if]

    [#switch groupId]
        [#case "_global"]
        [#case "_global_"]
        [#case "__global__"]
            [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : true,
                    "IsLocal" : false
                } ]
            [#break]

        [#case "_segment"]
        [#case "_segment_"]
        [#case "__segment__"]
            [#local segmentCIDR = [] ]
            [#list getZones() as zone]
                [#local zoneIP = getExistingReference(
                    formatResourceId(AWS_EIP_RESOURCE_TYPE, "mgmt", "nat", zone.Id)
                )]
                [#if zoneIP?has_content]
                    [#local segmentCIDR += [zoneIP + "/32" ] ]
                [/#if]
            [/#list]
            [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : segmentCIDR
                } ]
            [#break]

        [#case "_tier"]

            [#if occurrence?has_content ]
                [#if occurrence.Core.Type == "network"  ]
                    [#assign networkResources = occurrence.State.Resources ]
                [#else]
                    [#local occurrenceTier = getTier(occurrence.Core.Tier.Id) ]
                    [#local networkLinkTarget = getLinkTarget(occurrence, occurrenceTier.Network.Link, false )]
                    [#local networkResources = networkLinkTarget.State.Resources ]
                [/#if]

                [#local tier = getTier(lookupTier) ]
                [#local tierResources = networkResources["subnets"][tier.Id] ]

                [#local tierSubnets = []]
                [#list tierResources as zone,resource ]
                    [#if (lookupZone?has_content && zone == lookupZone) || ! (lookupZone?has_content) ]
                        [#local tierSubnets += [ resource.subnet.Address ] ]
                    [/#if]
                [/#list]
                [#return
                    {
                        "Id" : groupDetailId,
                        "Name" : groupDetailId,
                        "IsOpen" : false,
                        "IsLocal" : true,
                        "CIDR" : tierSubnets
                    } ]
            [#else]
                [#return
                    {
                        "Id" : groupDetailId,
                        "IsOpen" : true,
                        "CIDR" : []
                    }]

                [@fatal
                    message="Local network details required"
                    context=group
                    detail="To use the localnet IP Address group please provide the occurrence of the item using it"
                /]
            [/#if]
            [#break]

        [#case "_localnet"]
        [#case "_localnet_"]
        [#case "__localnet__"]

            [#if occurrence?has_content ]

                [#if occurrence.Core.Type == "network" ]
                    [#local networkCIDR = occurrence.Configuration.Solution.Address.CIDR ]
                [#else]
                    [#local occurrenceTier = getTier(occurrence.Core.Tier.Id) ]
                    [#local network = getLinkTarget(occurrence, occurrenceTier.Network.Link, false )]
                    [#local networkCIDR = (network.Configuration.Solution.Address.CIDR)!"HamletFatal: local network configuration not found" ]
                [/#if]

                [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : [ networkCIDR ]
                } ]
            [#else]
                [#return
                    {
                        "Id" : groupId,
                        "IsOpen" : true,
                        "CIDR" : []
                    }]

                [@fatal
                    message="Local network details required"
                    context=group
                    detail="To use the localnet IP Address group please provide the occurrence of the item using it"
                /]
            [/#if]
            [#break]

        [#case "_localhost"]
        [#case "_localhost_"]
        [#case "__localhost__"]
            [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : [ "127.0.0.1/32" ]
                } ]
            [#break]

        [#case "_named"]
        [#case "__named"]
            [#return
                {
                    "Id": groupDetailId,
                    "Name" : groupDetailId,
                    "IsOpen" : false,
                    "IsLocal" : true,
                    "CIDR" : [ ],
                    "NamedPrefix" : [lookupName]
                }
            ]

        [#default]
            [#if (ipAddressGroups[groupId]!{})?has_content ]
                [#return ipAddressGroups[groupId] ]
            [#else]
                [@fatal
                    message="Unknown IP address group"
                    context=group /]
                [#-- Treat missing group as open --]
                [#return
                    {
                        "Id" : groupId,
                        "IsOpen" : true,
                        "IsLocal" : false,
                        "CIDR" : []
                    } ]
            [/#if]
            [#break]
    [/#switch]
[/#function]

[#function getGroupCIDRs groups checkIsOpen=true occurrence={} asBoolean=false includeNamedPrefixes=true ]
    [#local cidrs = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local nextGroup = getIPAddressGroup(group, occurrence) ]
        [#if checkIsOpen && nextGroup.IsOpen!false]
            [#return valueIfTrue(false, asBoolean, ["0.0.0.0/0"]) ]
        [/#if]
        [#local cidrs += nextGroup.CIDR ]
        [#if includeNamedPrefixes && nextGroup.NamedPrefix?? ]
            [#local cidrs += nextGroup.NamedPrefix ]
        [/#if]
    [/#list]
    [#return valueIfTrue(cidrs?has_content, asBoolean, cidrs) ]
[/#function]
