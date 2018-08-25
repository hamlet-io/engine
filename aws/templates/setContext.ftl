[#ftl]

[#-- Component configuration is extended dynamically by each component type --]
[#assign componentConfiguration = {} ]
[#assign
    filterChildrenConfiguration = [
        "Tenant",
        "Product",
        {
            "Name" : "Tier",
            "Type" : "string",
            "Mandatory" : true
        },
        {
            "Name" : "Component",
            "Type" : "string",
            "Mandatory" : true
        },
        {
            "Name" : ["Function", "Subcomponent"],
            "Type" : "string"
        },
        {
            "Name" : ["Service", "Subcomponent"],
            "Type" : "string"
        },
        {
            "Name" : ["Task", "Subcomponent"],
            "Type" : "string"
        },
        {
            "Name" : ["PortMapping", "Port", "Subcomponent"],
            "Type" : "string"
        },
        {
            "Name" : ["Mount", "Subcomponent"],
            "Type" : "string"
        },
        {
            "Name" : ["Platform"],
            "Type" : "string"
        },
        {
            "Name" : "Instance",
            "Type" : "string"
        },
        {
            "Name" : "Version",
            "Type" : "string"
        }
    ]
]

[#assign
    linkChildrenConfiguration =
        filterChildrenConfiguration +
        [
            {
                "Name" : "Role",
                "Type" : "string"
            },
            {
                "Name" : "Direction",
                "Type" : "string"
            }
        ]
]

[#assign
    metricChildrenConfiguration = [
        {
            "Name" : "Name",
            "Type" : "string",
            "Mandatory" : true
        }
        {
            "Name" : "Type",
            "Type" : "string",
            "Mandatory" : true
        }
        {
            "Name" : "LogPattern",
            "Type" : "string",
            "Default" : ""
        }
    ]
]

[#assign alertChildrenConfiguration = [
        "Description",
        {
            "Name" : "Name",
            "Type" : "string",
            "Mandatory" : true
        },
        {
            "Name" : "Metric",
            "Children" : [
                {
                    "Name" : "Name",
                    "Type" : "string",
                    "Mandatory" : true
                },
                {
                    "Name" : "Type",
                    "Type" : "string",
                    "Mandatory" : true
                }
            ]
        },
        {
            "Name" : "Threshold",
            "Type" : "number",
            "Default" : 1
        },
        {
            "Name" : "Severity",
            "Type" : "string",
            "Default" : "Info"
        },
        {
            "Name" : "Namespace",
            "Type" : "string",
            "Default" : ""
        },
        {
            "Name" : "Comparison",
            "Type" : "string",
            "Default" : "Threshold"
        },
        {
            "Name" : "Operator",
            "Type" : "string",
            "Default" : "GreaterThanOrEqualToThreshold"
        },
        {
            "Name" : "Time",
            "Type" : "number",
            "Default" : 300
        },
        {
            "Name" : "Periods",
            "Type" : "number",
            "Default" : 1
        },
        {
            "Name" : "Statistic",
            "Type" : "string",
            "Default" : "Sum"
        },
        {
            "Name" : "ReportOk",
            "Type" : "boolean",
            "Default" : false
        },
        {
            "Name" : "MissingData",
            "Type" : "string",
            "Default" : "notBreaching"
        }
    ]
]

[#assign lbChildConfiguration = [
        {
            "Name" : "Tier",
            "Type" : "string",
            "Mandatory" : true
        },
        {
            "Name" : "Component",
            "Type" : "string",
            "Mandatory" : true
        },
        {
            "Name" : "LinkName",
            "Type" : "string",
            "Default" : "lb"
        },
        {
            "Name" : "Instance",
            "Type" : "string"
        },
        {
            "Name" : "Version",
            "Type" : "string"
        },
        {
            "Name" : "Path",
            "Type" : "string",
            "Default" : ""
        },
        {
            "Name" : ["PortMapping", "Port"],
            "Type" : "string",
            "Default" : ""
        },
        {
            "Name" : "Priority",
            "Type" : "number",
            "Default" : 100
        },
        {
            "Name" : "TargetGroup",
            "Type" : "string",
            "Default" : ""
        }
    ]
]

[#assign wafChildConfiguration = [
        {
            "Name" : "IPAddressGroups",
            "Type" : "array",
            "Mandatory" : true
        },
        {
            "Name" : "Default",
            "Type" : "string",
            "Values" : ["ALLOW", "BLOCK"],
            "Default" : "BLOCK"
        },
        {
            "Name" : "RuleDefault",
            "Type" : "string",
            "Values" : ["ALLOW", "BLOCK"],
            "Default" : "ALLOW"
        }
    ]
]

[#include idList]
[#include nameList]
[#include policyList]
[#include resourceList]
[#include "common.ftl"]

[#-- Name prefixes --]
[#assign shortNamePrefixes = [] ]
[#assign fullNamePrefixes = [] ]
[#assign cmdbProductLookupPrefixes = [] ]
[#assign segmentQualifiers = [] ]

[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]

[#assign settingsObject = settings?eval ]

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
[#assign logFiles = blueprintObject.LogFiles ]
[#assign logFileGroups = blueprintObject.LogFileGroups]
[#assign logFileProfiles = blueprintObject.LogFileProfiles ]

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

    [#assign shortNamePrefixes += [productId] ]
    [#assign fullNamePrefixes += [productName] ]
    [#assign cmdbProductLookupPrefixes += ["shared"] ]

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

    [#if blueprintObject.Environment?? ]
        [#assign environmentId = blueprintObject.Environment.Id ]
        [#assign environmentObject = environments[environmentId]]
        [#assign environmentName = environmentObject.Name]
        [#assign categoryId = segmentObject.Category!environmentObject.Category]
        [#assign categoryName = segmentObject.Category!environmentObject.Category]
        [#assign categoryObject = categories[categoryId]]

        [#assign shortNamePrefixes += [environmentId] ]
        [#assign fullNamePrefixes += [environmentName] ]
        [#assign segmentQualifiers += [environmentId, environmentName, segmentId, segmentName] ]

        [#assign cmdbProductLookupPrefixes +=
            [
                ["shared", segmentName],
                environmentName,
                [environmentName, segmentName]
            ] ]

        [#if (segmentName != "default") ]
            [#assign shortNamePrefixes += [segmentId] ]
            [#assign fullNamePrefixes += [segmentName] ]
        [/#if]

    [/#if]

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
    [#assign sshPerEnvironment = (segmentObject.SSH.PerSegment)!segmentObject.SSHPerSegment!true]
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

    [#assign operationsExpiration =
        (segmentObject.Operations.Expiration)!
        (environmentObject.Operations.Expiration)!""]
    [#assign operationsOffline =
        (segmentObject.Operations.Offline)!
        (environmentObject.Operations.Offline)!""]
    [#assign dataExpiration =
        (segmentObject.Data.Expiration)!
        (environmentObject.Data.Expiration)!""]
    [#assign dataOffline =
        (segmentObject.Data.Offline)!
        (environmentObject.Data.Offline)!""]
    [#assign dataPublicEnabled =
        (segmentObject.Data.Public.Enabled)!
        (environmentObject.Data.Public.Enabled)!false]
    [#assign dataPublicIPAddressGroups =
        (segmentObject.Data.Public.IPAddressGroups)!
        (environmentObject.Data.Public.IPAddressGroups)!
        (segmentObject.Data.Public.IPWhitelist)!
        (environmentObject.Data.Public.IPWhitelist)![] ]
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
                    [#if cidrEntry?contains("0.0.0.0")]
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
                    key : getEffectiveIPAddressGroup(value)
                } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- IP Address Groups - "global" is default --]
[#assign ipAddressGroups =
    getEffectiveIPAddressGroups(blueprintObject.IPAddressGroups!{} ) ]

[#function getIPAddressGroup group]
    [#local groupId = group?is_hash?then(group.Id, group) ]
    [#switch groupId]
        [#case "_global"]
        [#case "_global_"]
        [#case "__global__"]
            [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : true
                } ]
            [#break]

        [#case "_segment"]
        [#case "_segment_"]
        [#case "__segment__"]
            [#local segmentCIDR = [] ]
            [#list zones as zone]
                [#local zoneIP =
                    getExistingReference(
                        formatComponentEIPId("mgmt", "nat", zone),
                        IP_ADDRESS_ATTRIBUTE_TYPE
                    ) ]
                [#if zoneIP?has_content]
                    [#local segmentCIDR += [zoneIP] ]
                [/#if]
            [/#list]
            [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : false,
                    "CIDR" : segmentCIDR
                } ]
            [#break]
        
        [#case "_localnet"]
        [#case "_localnet_"]
        [#case "__localnet__"]
            [#return
            {
                "Id" : groupId,
                "Name" : groupId,
                "IsOpen" : false,
                "CIDR" : [ segmentObject.Network.CIDR.Address + "/" + segmentObject.Network.CIDR.Mask ]
            } ]
            [#break]

        [#default]
            [#if (ipAddressGroups[groupId]!{})?has_content ]
                [#return ipAddressGroups[groupId] ]
            [#else]
                [@cfException
                    mode=listMode
                    description="Unknown IP address group"
                    context=group /]
                [#-- Treat missing group as open --]
                [#return
                    {
                        "Id" : groupId,
                        "IsOpen" : true,
                        "CIDR" : []
                    } ]
            [/#if]
            [#break]
    [/#switch]
[/#function]

[#function getGroupCIDRs groups checkIsOpen=true]
    [#local cidrs = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local nextGroup = getIPAddressGroup(group) ]
        [#if checkIsOpen && nextGroup.IsOpen!false]
            [#return ["0.0.0.0/0"] ]
        [/#if]
        [#local cidrs += nextGroup.CIDR ]
    [/#list]
    [#return cidrs]
[/#function]



[#include "commonSegment.ftl"]
[#include "commonSolution.ftl"]
[#include "commonApplication.ftl"]



