[#ftl]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]

[#include idList]
[#include nameList]
[#include policyList]
[#include resourceList]
[#include "common.ftl"]

[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]
[#assign credentialsObject =
    credentials?has_content?then((credentials?eval).Credentials, {}) ]

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
[#assign powersOf2 = blueprintObject.PowersOf2]

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

[#-- IP Address Groups --]
[#-- IsOpen flag is for legacy builds, where the default was for access to be open --]
[#assign ipAddressGroups = (blueprintObject.IPAddressGroups)!{"IsOpen" : true} ]

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

[#-- Annotate IPAddressGroups --]
[#assign ipAddressGroupsUsage =
    {
        "DefaultUsageList" : ["es", "ssh", "http", "https", "waf", "publish", "dataPublic"]
    }
]
[#list ipAddressGroups as groupKey,groupValue]
    [#if groupValue?is_hash &&
            (groupValue.Enabled!true)]
        [#list groupValue as entryKey,entryValue]
            [#if entryValue?is_hash && 
                    (entryValue.Enabled!true) &&
                    ((entryValue.CIDR)?has_content ||
                        (entryValue.IsOpen!false))]
                [#assign isOpen = (entryValue.IsOpen)!false]
                [#assign cidrList = entryValue.CIDR?has_content?then(
                        asArray(entryValue.CIDR),
                        [])]
                [#assign newCIDR = []]
                [#list cidrList as CIDRBlock]
                    [#if CIDRBlock?contains("0.0.0.0")]
                        [#assign isOpen = true]
                    [#else]
                        [#assign newCIDR += [CIDRBlock]]
                    [/#if]
                [/#list]
                [#assign newUsage = (entryValue.Usage)?has_content?then(
                    asArray(entryValue.Usage),
                    ipAddressGroupsUsage.DefaultUsageList)]
                [#assign newValue = entryValue +
                    {
                        "Usage" : newUsage,
                        "CIDR" : newCIDR,
                        "IsOpen" : isOpen
                    }
                ]
                [#assign ipAddressGroups += 
                    {
                        groupKey : groupValue + 
                            {
                                entryKey : newValue
                            }
                    }
                ]
                [#list newUsage as usage]
                    [#assign usageGroups = (ipAddressGroupsUsage[usage])!{}]
                    [#assign usageEntries = (usageGroups[groupKey].Entries)!{}]
                    [#assign usageCIDR = (usageGroups[groupKey].CIDR)![] +
                                newCIDR]
                    [#assign usageIsOpen = (usageGroups[groupKey].IsOpen)!false ||
                                isOpen]
                    [#assign ipAddressGroupsUsage +=
                        {
                            usage : usageGroups +
                                {
                                    groupKey :  {
                                        "Id" : groupValue.Id,
                                        "Name" : groupValue.Name,
                                        "Entries" : usageEntries +
                                            {
                                                entryKey :  newValue
                                            },
                                        "CIDR" : usageCIDR,
                                        "IsOpen" : usageIsOpen
                                    }
                                }
                        }
                    ]
                [/#list]
            [/#if]
        [/#list]
    [/#if]
[/#list]

[#function isUsageOpen usage groupList]
    [#list groupList as group]
        [#if (ipAddressGroupsUsage[usage][group].IsOpen)!false]
            [#return true]
        [/#if]
    [/#list]
    [#return false]
[/#function]

[#function getUsageCIDRs usage groupList checkIsOpen=true]
    [#local cidrs = []]
    [#if groupList?has_content]
        [#list groupList as group]
            [#if (ipAddressGroupsUsage[usage][group])?has_content ]
                [#local usageGroup = ipAddressGroupsUsage[usage][group] ]
                [#if checkIsOpen &&
                        (usageGroup.IsOpen!false)]
                    [#return ["0.0.0.0/0"] ]
                [/#if]
                [#if usageGroup.CIDR?has_content]
                    [#local cidrs += usageGroup.CIDR ]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#if ipAddressGroups.IsOpen!false]
            [#return ["0.0.0.0/0"]]
        [/#if]
    [/#if]
    [#return cidrs]
[/#function]


[#include "commonSegment.ftl"]
[#include "commonSolution.ftl"]
[#include "commonApplication.ftl"]





