[#ftl]

[#include idList]
[#include nameList]
[#include policyList]
[#include resourceList]
[#include "common.ftl"]

[#-- Standard inputs --]
[#assign blueprintObject = blueprint?eval]
[#assign credentialsObject = {"Credentials" : {}}]
[#if credentials??]
    [#assign credentialsObject = (credentials?eval).Credentials]
[/#if]
[#assign appSettingsObject = {}]
[#if appsettings??]
    [#assign appSettingsObject = appsettings?eval]
[/#if]
[#assign stackOutputsObject = []]
[#if stackOutputs??]
    [#assign stackOutputsObject = stackOutputs?eval]
[/#if]

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
[#if region??]
    [#assign regionId = region]
    [#assign regionObject = regions[regionId]]
    [#assign regionName = regionObject.Name]
[/#if]
[#if accountRegion??]
    [#assign accountRegionId = accountRegion]
    [#assign accountRegionObject = regions[accountRegionId]]
    [#assign accountRegionName = accountRegionObject.Name]
[/#if]
[#if productRegion??]
    [#assign productRegionId = productRegion]
    [#assign productRegionObject = regions[productRegionId]]
    [#assign productRegionName = productRegionObject.Name]
[/#if]

[#-- Tenants --]
[#assign tenants = (blueprintObject.Tenants)!{}]
[#assign tenantObject = (blueprintObject.Tenant)!(tenants[tenant])!{}]
[#if tenantObject?has_content]
    [#assign tenantId = tenantObject.Id]
    [#assign tenantName = tenantObject.Name]
    [#assign tenants += { tenantId : tenantObject }]
[/#if]

[#-- Domains --]
[#assign domains = (blueprintObject.Domains)!{}]
[#if (tenantObject.Domain)??]
    [#if tenantObject.Domain?is_hash && (tenantObject.Domain.Validation)??]
        [#assign domains += {"Validation" : tenantObject.Domain.Validation}]
    [/#if]
[/#if]

[#-- Certificates --]
[#assign certificates = (blueprintObject.Certificates)!{}]

[#-- Accounts --]
[#assign accounts = (blueprintObject.Accounts)!{}]
[#assign accountObject = (blueprintObject.Account)!(accounts[account])!{}]
[#if accountObject?has_content]
    [#assign accountId = accountObject.Id]
    [#assign accountName = accountObject.Name]
    [#-- Legacy code to support a domain definition within an account --]
    [#if accountObject.Domain??]
        [#if accountObject.Domain?is_hash]
            [#assign accountDomain = accountObject.Domain.Certificate.Id]
            [#assign domains += { accountDomain : accountObject.Domain }]
            [#assign accountObject += {"Domain" : accountDomain}]
        [#else]
            [#assign accountDomain = accountObject.Domain]        
        [/#if]
    [/#if]
    [#assign credentialsBucket = getKey(formatAccountS3Id("credentials"))]
    [#assign codeBucket = getKey(formatAccountS3Id("code"))]
    [#assign registryBucket = getKey(formatAccountS3Id("registry"))]
    [#assign accounts += { accountId : accountObject }]
[/#if]

[#-- Products --]
[#assign products = (blueprintObject.Products)!{}]
[#assign productObject = (blueprintObject.Product)!(products[product])!{}]
[#if productObject?has_content]
    [#assign productId = productObject.Id]
    [#assign productName = productObject.Name]
    [#-- Legacy code to support a domain definition within a product --]
    [#if productObject.Domain??]
        [#if productObject.Domain?is_hash]
            [#assign productDomain = productObject.Domain.Certificate.Id]
            [#assign domains += { productDomain : productObject.Domain }]
            [#assign productObject += {"Domain" : productDomain}]
        [#else]
            [#assign productDomain = productObject.Domain]        
        [/#if]
    [/#if]
    [#assign products += { productId : productObject }]
[/#if]

[#-- IP Address Groups --]
[#-- IsOpen flag is for legacy builds, where the default was for access to be open --]
[#assign ipAddressGroups = (blueprintObject.IPAddressGroups)!{"IsOpen" : true}]

[#-- Segments --]
[#assign segments = (blueprintObject.Segments)!{}]
[#assign segmentObject = (blueprintObject.Segment)!(segments[segment])!{}]
[#if segmentObject?has_content]
    [#assign segmentId = segmentObject.Id]
    [#assign segmentName = segmentObject.Name]
    [#assign internetAccess = segmentObject.InternetAccess]
    [#assign natEnabled = internetAccess && ((segmentObject.NAT.Enabled)!true)]
    [#assign natPerAZ = natEnabled && ((segmentObject.NAT.MultiAZ)!false)]
    [#assign natHosted = (segmentObject.NAT.Hosted)!false]
    [#assign sshEnabled = internetAccess &&
                            ((segmentObject.SSH.Enabled)!true)]
    [#assign sshActive = sshEnabled &&
                            ((segmentObject.SSH.Active)!false)]
    [#assign sshPerSegment = (segmentObject.SSH.PerSegment)!segmentObject.SSHPerSegment!true]
    [#assign sshStandalone = ((segmentObject.SSH.Standalone)!false) || natHosted ]
    [#assign operationsBucket = "unknown"]
    [#assign operationsBucketSegment = "segment"]
    [#assign operationsBucketType = "ops"]
    [#if getKey(formatSegmentS3Id("ops"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3Id("ops"))]        
    [/#if]
    [#if getKey(formatSegmentS3Id("operations"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3Id("operations"))]        
        [#assign operationsBucketType = "operations"]
    [/#if]
    [#if getKey(formatSegmentS3Id("logs"))?has_content]
        [#assign operationsBucket = getKey(formatSegmentS3Id("logs"))]        
        [#assign operationsBucketType = "logs"]
    [/#if]
    [#if getKey(formatContainerS3Id("logs"))?has_content]
        [#assign operationsBucket = getKey(formatContainerS3Id("logs"))]        
        [#assign operationsBucketSegment = "container"]
        [#assign operationsBucketType = "logs"]
    [/#if]

    [#assign dataBucket = "unknown"]
    [#assign dataBucketSegment = "segment"]
    [#assign dataBucketType = "data"]
    [#if getKey(formatSegmentS3Id("data"))?has_content]
        [#assign dataBucket = getKey(formatSegmentS3Id("data"))]        
    [/#if]
    [#if getKey(formatSegmentS3Id("backups"))?has_content]
        [#assign dataBucket = getKey(formatSegmentS3Id("backups"))]        
        [#assign dataBucketType = "backups"]
    [/#if]
    [#if getKey(formatContainerS3Id("backups"))?has_content]
        [#assign dataBucket = getKey(formatContainerS3Id("backups"))]        
        [#assign dataBucketSegment = "container"]
        [#assign dataBucketType = "backups"]
    [/#if]
    [#assign segmentDomain = getKey(formatSegmentDomainId())]
    [#assign segmentDomainQualifier = getKey(formatSegmentDomainQualifierId())]
    [#assign certificateId = getKey(formatSegmentDomainCertificateId())]
    [#assign vpc = getKey(formatVPCId())]
    [#assign sshFromProxySecurityGroup = getKey(formatSSHFromProxySecurityGroupId())]
    [#if segmentObject.Environment??]
        [#assign environmentId = segmentObject.Environment]
        [#assign environmentObject = environments[environmentId]]
        [#assign environmentName = environmentObject.Name]
        [#assign categoryId = segmentObject.Category!environmentObject.Category]
        [#assign categoryObject = categories[categoryId]]
    [/#if]
    [#assign operationsExpiration = (segmentObject.Operations.Expiration)!(environmentObject.Operations.Expiration)!"none"]
    [#assign dataExpiration = (segmentObject.Data.Expiration)!(environmentObject.Data.Expiration)!"none"]
    [#-- Legacy code to support IP address group (formerly block) definitions within a segment --]
    [#if segmentObject.IPAddressBlocks??]
        [#if segmentObject.IPAddressBlocks?is_hash]
            [#assign segmentIPAddressGroups = []]
            [#list segmentObject.IPAddressBlocks as group,value]
                [#if value?is_hash]
                    [#assign segmentIPAddressGroups += [group]]
                    [#assign ipAddressGroups += { group : value }]
                [/#if]
            [/#list]
            [#assign segmentObject += {"IPAddressGroups" : segmentIPAddressGroups}]
        [/#if]
    [/#if]
    [#assign segments += { segmentId : segmentObject }]
[/#if]

[#-- Solution --]
[#if blueprintObject.Solution??]
    [#assign solutionObject = blueprintObject.Solution]
    [#assign solnMultiAZ = solutionObject.MultiAZ!(environmentObject.MultiAZ)!false]
[/#if]

[#-- Required tiers --]
[#assign tiers = []]
[#list segmentObject.Tiers.Order as tierId]
    [#if isTier(tierId)]
        [#assign tier = getTier(tierId)]
        [#if tier.Components??
            || ((tier.Required)!false)
            || (tierId == "mgmt")]
            [#assign tiers += [tier + 
                {
                    "Index" : tierId?index,
                    "RouteTable" : internetAccess?then(tier.RouteTable, "internal")
                }]]
        [/#if]
    [/#if]
[/#list]

[#-- Required zones --]
[#assign zones = []]
[#list segmentObject.Zones.Order as zoneId]
    [#if regions[region].Zones[zoneId]??]
        [#assign zone = regions[region].Zones[zoneId]]
        [#assign zones += [zone +  
            {"Index" : zoneId?index}]]
    [/#if]
[/#list]

[#-- Annotate IPAddressGroups --]
[#assign ipAddressGroupsUsage = { "DefaultUsageList" : ["es", "ssh", "http", "https", "waf"]}]
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
                        entryValue.CIDR?is_sequence?then(
                            entryValue.CIDR,
                            [entryValue.CIDR]),
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
                    entryValue.Usage?is_sequence?then(
                        entryValue.Usage,
                        [entryValue.Usage]),
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
            [#if (ipAddressGroupsUsage[usage][group])?has_content]
                [#local usageGroup = ipAddressGroupsUsage[usage][group]]
                [#if checkIsOpen &&
                        (usageGroup.IsOpen!false)]
                    [#return ["0.0.0.0/0"]]
                [/#if]
                [#if usageGroup.CIDR?has_content]
                    [#local cidrs += usageGroup.CIDR]
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





