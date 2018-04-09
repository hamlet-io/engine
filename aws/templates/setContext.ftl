[#ftl]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]
[#assign
    filterChildrenConfiguration = [
        "Tenant",
        "Product",
        {
            "Name" : "Tier",
            "Mandatory" : true
        },
        {
            "Name" : "Component",
            "Mandatory" : true
        },
        {
            "Name" : ["Function", "Subcomponent"]
        },
        {
            "Name" : ["Service", "Subcomponent"]
        },
        {
            "Name" : ["Task", "Subcomponent"]
        },
        {
            "Name" : ["Port", "Subcomponent"]
        },
        "Instance",
        "Version"
    ]
]

[#assign
    linkChildrenConfiguration =
        filterChildrenConfiguration +
        [
            "Role",
            "Direction"
        ]
]


[#include idList]
[#include nameList]
[#include policyList]
[#include resourceList]
[#include "common.ftl"]

[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]

[#-- Legacy credentials formats had a top level Credentials attribute --]
[#assign credentialsObject =
    credentials?has_content?then(credentials?eval, {}) ]
[#assign credentialsObject += credentialsObject.Credentials!{} ]

[#assign appSettingsObject =
    appsettings?has_content?then(appsettings?eval, {}) ]

[#assign stackOutputsList =
    stackOutputs?has_content?then(stackOutputs?eval, []) ]

[#-- Reference data --]
[#assign regions = blueprintObject.Regions]
[#assign environments = blueprintObject.Environments]
[#assign categories = blueprintObject.Categories]
[#assign routeTables = blueprintObject.RouteTables]
[#assign networkACLs = blueprintObject.NetworkACLs]
[#assign storage = blueprintObject.Storage]
[#assign processors = blueprintObject.Processors]
[#assign ports = blueprintObject.Ports]
[#assign portMappings = blueprintObject.PortMappings]

[#-- Regions --]
[#if region?has_content]
    [#assign regionId = region]
    [#assign regionObject = regions[regionId] ]
    [#assign regionName = regionObject.Name]
[/#if]
[#if accountRegion?has_content]
    [#assign accountRegionId = accountRegion]
    [#assign accountRegionObject = regions[accountRegionId] ]
    [#assign accountRegionName = accountRegionObject.Name]
[/#if]
[#if productRegion?has_content]
    [#assign productRegionId = productRegion]
    [#assign productRegionObject = regions[productRegionId] ]
    [#assign productRegionName = productRegionObject.Name]
[/#if]

[#-- Tenants --]
[#assign tenants = (blueprintObject.Tenants)!{} ]
[#assign tenantObject = (blueprintObject.Tenant)!(tenants[tenant])!{} ]
[#if tenantObject?has_content]
    [#assign tenantId = tenantObject.Id]
    [#assign tenantName = tenantObject.Name]
    [#assign tenants += {tenantId : tenantObject} ]
[/#if]

[#-- Domains --]
[#assign domains = (blueprintObject.Domains)!{} ]

[#-- Certificates --]
[#assign certificates = (blueprintObject.Certificates)!{} ]

[#-- Accounts --]
[#assign accounts = (blueprintObject.Accounts)!{} ]
[#assign accountObject = (blueprintObject.Account)!(accounts[account])!{} ]
[#if accountObject?has_content]
    [#assign accountId = accountObject.Id]
    [#assign accountName = accountObject.Name]
    [#assign accounts += {accountId : accountObject} ]

    [#assign credentialsBucket = getExistingReference(formatAccountS3Id("credentials")) ]
    [#assign codeBucket = getExistingReference(formatAccountS3Id("code")) ]
    [#assign registryBucket = getExistingReference(formatAccountS3Id("registry")) ]

    [#assign categoryName = "account"]

[/#if]

[#-- Products --]
[#assign products = (blueprintObject.Products)!{} ]
[#assign productObject = (blueprintObject.Product)!(products[product])!{} ]
[#if productObject?has_content]
    [#assign productId = productObject.Id]
    [#assign productName = productObject.Name]
    [#assign products += {productId : productObject} ]

    [#assign productDomain = productObject.Domain!""]

[/#if]

[#-- Country Groups --]
[#assign countryGroups = (blueprintObject.CountryGroups)!{} ]

[#-- Segments --]
[#assign segments = (blueprintObject.Segments)!{} ]
[#assign segmentObject = (blueprintObject.Segment)!(segments[segment])!{} ]
[#if segmentObject?has_content]
    [#assign segmentId = segmentObject.Id]
    [#assign segmentName = segmentObject.Name]
    [#assign segments += {segmentId : segmentObject} ]

    [#assign vpc = getExistingReference(formatVPCId())]
    [#assign network = segmentObject.Network!segmentObject ]
    [#assign baseAddress = network.CIDR.Address?split(".")]
    [#assign addressOffset = baseAddress[2]?number*256 + baseAddress[3]?number]
    [#assign addressesPerTier = powersOf2[getPowerOf2(powersOf2[32 - network.CIDR.Mask]/(network.Tiers.Order?size))]]
    [#assign addressesPerZone = powersOf2[getPowerOf2(addressesPerTier / (network.Zones.Order?size))]]
    [#assign subnetMask = 32 - powersOf2?seq_index_of(addressesPerZone)]
    [#assign dnsSupport = network.DNSSupport]
    [#assign dnsHostnames = network.DNSHostnames]

    [#assign rotateKeys = (segmentObject.RotateKeys)!true]

    [#assign internetAccess = network.InternetAccess]

    [#assign natEnabled = internetAccess && ((segmentObject.NAT.Enabled)!true)]
    [#assign natHosted = (segmentObject.NAT.Hosted)!false]

    [#assign sshEnabled = internetAccess &&
                            ((segmentObject.SSH.Enabled)!true)]
    [#assign sshActive = sshEnabled &&
                            ((segmentObject.SSH.Active)!false)]
    [#assign sshPerSegment = (segmentObject.SSH.PerSegment)!segmentObject.SSHPerSegment!true]
    [#assign sshStandalone = ((segmentObject.SSH.Standalone)!false) || natHosted ]
    [#assign sshFromProxySecurityGroup = getExistingReference(formatSSHFromProxySecurityGroupId())]

    [#assign operationsBucket =
        firstContent(
            getExistingReference(formatS3OperationsId()),
            formatSegmentBucketName("ops"))]

    [#assign dataBucket =
        firstContent(
            getExistingReference(formatS3DataId()),
            formatSegmentBucketName("data"))]

    [#if segmentObject.Environment??]
        [#assign environmentId = segmentObject.Environment]
        [#assign environmentObject = environments[environmentId]]
        [#assign environmentName = environmentObject.Name]
        [#assign categoryId = segmentObject.Category!environmentObject.Category]
        [#assign categoryName = segmentObject.Category!environmentObject.Category]
        [#assign categoryObject = categories[categoryId]]
    [/#if]

    [#assign operationsExpiration =
        (segmentObject.Operations.Expiration)!
        (environmentObject.Operations.Expiration)!""]
    [#assign dataExpiration =
        (segmentObject.Data.Expiration)!
        (environmentObject.Data.Expiration)!""]
    [#assign dataPublicEnabled =
        (segmentObject.Data.Public.Enabled)!
        (environmentObject.Data.Public.Enabled)!false]
    [#assign dataPublicWhiteList =
        (segmentObject.Data.Public.IPWhitelist)!
        (environmentObject.Data.Public.IPWhitelist)![]]
[/#if]

[#-- Solution --]
[#if blueprintObject.Solution?has_content]
    [#assign solutionObject = blueprintObject.Solution]
    [#assign solnMultiAZ = solutionObject.MultiAZ!(environmentObject.MultiAZ)!false]
    [#assign RDSAutoMinorVersionUpgrade = (segmentObject.RDS.AutoMinorVersionUpgrade)!(solutionObject.RDS.AutoMinorVersionUpgrade)!(environmentObject.RDS.AutoMinorVersionUpgrade)!true]
    [#assign natPerAZ = natEnabled &&
                        (
                            (natHosted && solnMultiAZ) ||
                            ((segmentObject.NAT.MultiAZ)!false)
                        ) ]
[/#if]

[#-- Required tiers --]
[#list segmentObject.Tiers.Order as tierId]
    [#assign blueprintTier = (blueprintObject.Tiers[tierId])!{}]
    [#if ! (blueprintTier?has_content) ]
        [#continue]
    [/#if]
    [#assign tierNetwork =
        {
            "Enabled" : false,
            "RouteTable" : "internal",
            "NetworkACL" : "open"
        } ]
    [#if blueprintTier.Components?has_content || ((blueprintTier.Required)!false)]
        [#if (blueprintTier.Network.Enabled)!false ]
            [#list segmentObject.Network.Tiers.Order![] as networkTier]
                [#if networkTier == tierId]
                    [#assign tierNetwork =
                        blueprintTier.Network +
                        {
                            "Index" : networkTier?index,
                            "RouteTable" : internetAccess?then(blueprintTier.Network.RouteTable!"internal", "internal"),
                            "NetworkACL" : blueprintTier.Network.NetworkACL!"open"
                        } ]
                    [#break]
                [/#if]
            [/#list]
        [/#if]
        [#assign tiers += [ blueprintTier +  { "Network" : tierNetwork } ] ]
    [/#if]
[/#list]

[#-- Required zones --]
[#assign zones = [] ]
[#list segmentObject.Network.Zones.Order as zoneId]
    [#if regions[region].Zones[zoneId]?has_content]
        [#assign zone = regions[region].Zones[zoneId] ]
        [#assign zones +=
            [
                zone +
                {
                    "Index" : zoneId?index
                }
            ]
        ]
    [/#if]
[/#list]

[#function getSubnets tier asReferences=true includeZone=false]
    [#local result = [] ]
    [#list zones as zone]
        [#local subnetId = formatSubnetId(tier, zone)]

        [#local subnetId = asReferences?then(
                                getReference(subnetId),
                                subnetId)]

        [#local result +=
            [
                includeZone?then(
                    {
                        "subnetId" : subnetId,
                        "zone" : zone
                    },
                    subnetId
                )
            ]
        ]
    [/#list]
    [#return result]
[/#function]

[#-- Apply usage defaults and filter out open cidrs --]
[#function getEffectiveIPAddressGroup group]
    [#local groupId = "unknown" ]
    [#local groupName = "unknown" ]
    [#-- Support manually forcing group to always be considered open --]
    [#local groupIsOpen = false ]
    [#local groupUsage = [] ]
    [#local entries = {} ]

    [#if group?is_hash && group.Enabled!true]
        [#local groupId = group.Id!groupId ]
        [#local groupName = group.Name!groupName ]
        [#local groupIsOpen = group.IsOpen!groupIsOpen ]

        [#list group as key,value]
            [#if value?is_hash && value.Enabled!true]
                [#local isOpen = (value.IsOpen)!false ]
                [#local cidrEntries = asFlattenedArray(value.CIDR![]) ]
                [#if cidrEntries?has_content || isOpen ]
                    [#local cidrs = [] ]
                    [#list cidrEntries as cidrEntry ]
                        [#if cidrEntry?contains("0.0.0.0")]
                            [#local isOpen = true]
                        [#else]
                            [#local cidrs += [cidrEntry] ]
                        [/#if]
                    [/#list]
                    [#local entryUsage =
                        valueIfContent(
                            asFlattenedArray(value.Usage![]),
                            value.Usage![],
                            [
                                "es", "ssh", "http", "https",
                                "waf", "publish", "dataPublic"
                            ]
                        ) ]
                    [#local entries +=
                        {
                            key : {
                                "CIDR" : cidrs,
                                "IsOpen" : isOpen,
                                "Usage" : entryUsage
                            }
                        }
                    ]
                    [#local groupUsage = getUniqueArrayElements(
                        groupUsage,
                        entryUsage) ]
                [/#if]
            [/#if]
        [/#list]
    [/#if]
    [#return
        {
            "Id" : groupId,
            "Name" : groupName,
            "IsOpen" : groupIsOpen,
            "Usage" : groupUsage,
            "Entries" : entries
        } ]
[/#function]

[#function getGroupUsage usage group]
    [#local isOpen = group.IsOpen ]
    [#local cidrs = [] ]
    [#local entries = {} ]

    [#list group.Entries as key,value]
        [#if value.Usage?seq_contains(usage) ]
            [#local isOpen = isOpen || value.IsOpen ]
            [#local cidrs += value.CIDR ]
            [#local entries +=
                {
                    key : value
                }
            ]
        [/#if]
    [/#list]
    [#return
        {
            "Id" : group.Id,
            "Name" : group.Name,
            "IsOpen" : isOpen,
            "CIDR" : cidrs,
            "Entries" : entries
        }
    ]
[/#function]

[#function getEffectiveUsages groups]
    [#local result = {} ]
    [#list groups as key,value]
        [#local effectiveGroup = getEffectiveIPAddressGroup(value) ]
        [#list effectiveGroup.Usage as usage]
            [#local result +=
                {
                    usage :
                        (result[usage]!{}) +
                        {
                            effectiveGroup.Id : getGroupUsage(usage, effectiveGroup)
                        }
                }
            ]
        [/#list]
    [/#list]
    [#return result ]
[/#function]

[#-- IP Address Groups for each usage --]
[#assign ipAddressGroupsUsage =
    getEffectiveUsages(blueprintObject.IPAddressGroups!{}) ]

[#function getUsage usage]
    [#return ipAddressGroupsUsage[usage]!{} ]
[/#function]

[#function isUsageOpen usage groups]
    [#list asFlattenedArray(groups) as group]
        [#if (getUsage(usage)[group].IsOpen)!false ]
            [#return true]
        [/#if]
    [/#list]
    [#return false]
[/#function]

[#function getUsageCIDRs usage groups checkIsOpen=true]
    [#local cidrs = []]
    [#list asFlattenedArray(groups) as group]
        [#local usageGroup = getUsage(usage)[group]!{} ]
        [#if checkIsOpen && usageGroup.IsOpen!false]
            [#return ["0.0.0.0/0"] ]
        [/#if]
        [#local cidrs += usageGroup.CIDR![] ]
    [/#list]
    [@cfDebug
        listMode
        {
            "Usage" : usage,
            "Groups" : groups,
            "CIDR" : cidrs
        }
        false
    /]
    [#return cidrs]
[/#function]


[#include "commonSegment.ftl"]
[#include "commonSolution.ftl"]
[#include "commonApplication.ftl"]



