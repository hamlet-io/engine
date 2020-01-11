[#ftl]
[#include "engine.ftl"]
[#include "common.ftl"]
[#include "openapi.ftl"]

[#-- Shared Provider Configurations --]
[@includeSharedComponentConfiguration component="baseline" /]

[#-- Temporary AWS stuff --]
[#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws") ]
    [@includeProviderConfiguration provider=AWS_PROVIDER /]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="baseline" /]
    [@includeProviderComponentConfiguration provider="aws" component="baseline" services="baseline" /]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="s3" /]
    [@includeProviderComponentConfiguration provider="aws" component="s3" services="s3" /]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="ec2" /]
    [@includeProviderComponentConfiguration provider="aws" component="ec2" services=["ec2", "vpc"] /]
[/#if]

[#-- Name prefixes --]
[#assign shortNamePrefixes = [] ]
[#assign fullNamePrefixes = [] ]
[#assign cmdbProductLookupPrefixes = [] ]
[#assign segmentQualifiers = [] ]

[#-- Testing --]
[@includeSharedReferenceConfiguration referenceType=TESTCASE_REFERENCE_TYPE /]
[@addReferenceData type=TESTCASE_REFERENCE_TYPE data=blueprintObject.TestCases /]
[#assign testCases = referenceData.TestCases ]

[@includeSharedReferenceConfiguration referenceType=TESTPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=TESTPROFILE_REFERENCE_TYPE data=blueprintObject.TestProfiles /]
[#assign testProfiles = referenceData.TestProfiles ]

[#-- Regions --]
[@includeSharedReferenceConfiguration referenceType=REGION_REFERENCE_TYPE /]
[@addReferenceData type=REGION_REFERENCE_TYPE data=blueprintObject.Regions /]
[#assign regions = referenceData.Regions ]

[#-- Categories --]
[@includeSharedReferenceConfiguration referenceType=CATEGORY_REFERENCE_TYPE /]
[@addReferenceData type=CATEGORY_REFERENCE_TYPE data=blueprintObject.Categories /]
[#assign categories = referenceData.Categories]

[#-- Environments --]
[@includeSharedReferenceConfiguration referenceType=ENVIRONMENT_REFERENCE_TYPE /]
[@addReferenceData type=ENVIRONMENT_REFERENCE_TYPE data=blueprintObject.Environments /]
[#assign environments = referenceData.Environments]

[#-- Storage Profiles --]
[@includeSharedReferenceConfiguration referenceType=STORAGE_REFERENCE_TYPE /]
[@addReferenceData type=STORAGE_REFERENCE_TYPE data=blueprintObject.Storage /]
[#assign storage = referenceData.Storage]

[#-- Processor Profiles --]
[@includeSharedReferenceConfiguration referenceType=PROCESSOR_REFERENCE_TYPE /]
[@addReferenceData type=PROCESSOR_REFERENCE_TYPE data=blueprintObject.Processors /]
[#assign processors = referenceData.Processors]

[#-- Ports --]
[@includeSharedReferenceConfiguration referenceType=PORT_REFERENCE_TYPE /]
[@addReferenceData type=PORT_REFERENCE_TYPE data=blueprintObject.Ports /]
[#assign ports = referenceData.Ports]

[#-- PortMappings --]
[@includeSharedReferenceConfiguration referenceType=PORTMAPPING_REFERENCE_TYPE /]
[@addReferenceData type=PORTMAPPING_REFERENCE_TYPE data=blueprintObject.PortMappings /]
[#assign portMappings = referenceData.PortMappings]

[#-- Log Files --]
[@includeSharedReferenceConfiguration referenceType=LOGFILE_REFERENCE_TYPE /]
[@addReferenceData type=LOGFILE_REFERENCE_TYPE data=blueprintObject.LogFiles /]
[#assign logFiles = referenceData.LogFiles ]

[#-- Log File Groups --]
[@includeSharedReferenceConfiguration referenceType=LOGFILEGROUP_REFERENCE_TYPE /]
[@addReferenceData type=LOGFILEGROUP_REFERENCE_TYPE data=blueprintObject.LogFileGroups /]
[#assign logFileGroups = referenceData.LogFileGroups]

[#-- Log File Profiles --]
[@includeSharedReferenceConfiguration referenceType=LOGFILEPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=LOGFILEPROFILE_REFERENCE_TYPE data=blueprintObject.LogFileProfiles /]
[#assign logFileProfiles = referenceData.LogFileProfiles ]

[#-- CORS Profiles --]
[@includeSharedReferenceConfiguration referenceType=CORSPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=CORSPROFILE_REFERENCE_TYPE data=blueprintObject.CORSProfiles /]
[#assign CORSProfiles = referenceData.CORSProfiles ]

[#-- Script Stores --]
[@includeSharedReferenceConfiguration referenceType=SCRIPTSTORE_REFERENCE_TYPE /]
[@addReferenceData type=SCRIPTSTORE_REFERENCE_TYPE data=blueprintObject.ScriptStores /]
[#assign scriptStores = referenceData.ScriptStores ]

[#-- Bootstraps --]
[@includeSharedReferenceConfiguration referenceType=BOOTSTRAP_REFERENCE_TYPE /]
[@addReferenceData type=BOOTSTRAP_REFERENCE_TYPE data=blueprintObject.Bootstraps /]
[#assign bootstraps = (referenceData.Bootstraps)!{} ]

[#-- Bootstrap Profiles--]
[@includeSharedReferenceConfiguration referenceType=BOOTSTRAPPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=BOOTSTRAPPROFILE_REFERENCE_TYPE data=blueprintObject.BootstrapProfiles /]
[#assign bootstrapProfiles = (referenceData.BootstrapProfiles)!{} ]

[#-- Security Profiles --]
[@includeSharedReferenceConfiguration referenceType=SECURITYPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=SECURITYPROFILE_REFERENCE_TYPE data=blueprintObject.SecurityProfiles /]
[#assign securityProfiles = referenceData.SecurityProfiles ]

[#-- Baseline Profiles --]
[@includeSharedReferenceConfiguration referenceType=BASELINEPROFILE_REFERENCE_TYPE /]
[@addReferenceData type=BASELINEPROFILE_REFERENCE_TYPE data=blueprintObject.BaselineProfiles /]
[#assign baselineProfiles = referenceData.BaselineProfiles ]

[#-- Log Filters --]
[@includeSharedReferenceConfiguration referenceType=LOGFILTER_REFERENCE_TYPE /]
[@addReferenceData type=LOGFILTER_REFERENCE_TYPE data=blueprintObject.LogFilters /]
[#assign logFilters = referenceData.LogFilters]

[#-- Network Endpoint Groups --]
[@includeSharedReferenceConfiguration referenceType=NETWORKENDPOINTGROUP_REFERENCE_TYPE /]
[@addReferenceData type=NETWORKENDPOINTGROUP_REFERENCE_TYPE data=blueprintObject.NetworkEndpointGroups /]
[#assign networkEndpointGroups = referenceData.NetworkEndpointGroups ]

[#-- Virtual Machine Image Profiles --]
[@includeSharedReferenceConfiguration referenceType=VIRTUAL_MACHINE_IMAGE_REFERENCE_TYPE /]
[@addReferenceData type=VIRTUAL_MACHINE_IMAGE_REFERENCE_TYPE data=blueprintObject.VMImageProfiles /]
[#assign vmImageProfiles = referenceData.VMImageProfiles]

[#-- Regions --]
[#if commandLineOptions.Regions.Segment?has_content]
    [#assign regionId = commandLineOptions.Regions.Segment]
    [#assign regionObject = regions[regionId] ]
[/#if]
[#if commandLineOptions.Regions.Account?has_content]
    [#assign accountRegionId = commandLineOptions.Regions.Account]
    [#assign accountRegionObject = regions[accountRegionId] ]
[/#if]

[#-- Tenants --]
[#assign tenants = (blueprintObject.Tenants)!{} ]
[#assign tenantObject = (blueprintObject.Tenant)!(tenants[tenant])!{} ]
[#if tenantObject?has_content]
    [#assign tenantId = tenantObject.Id!tenant]
    [#assign tenantName = tenantObject.Name!tenantId]
    [#assign tenants +=
        {
            tenantId :
                {
                    "Id" : tenantId,
                    "Name" : tenantName
                } +
                tenantObject
        } ]
[/#if]

[#-- Domains --]
[#assign domains =
    addIdNameToObjectAttributes(blueprintObject.Domains!{}) ]

[#-- Certificates --]
[#assign certificates =
    addIdNameToObjectAttributes(blueprintObject.Certificates!{}) ]

[#-- Accounts --]
[#assign accounts = (blueprintObject.Accounts)!{} ]
[#assign accountObject = (blueprintObject.Account)!(accounts[account])!{} ]
[#if accountObject?has_content]
    [#assign accountId = accountObject.Id!account]
    [#assign accountName = accountObject.Name!accountId]
    [#assign accounts +=
        {
            accountId :
                {
                    "Id" : accountId,
                    "Name" : accountName
                } +
                accountObject
        } ]

    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
        [#assign credentialsBucket = getExistingReference(formatAccountS3Id("credentials"))]
        [#assign codeBucket = getExistingReference(formatAccountS3Id("code")) ]
        [#assign registryBucket = getExistingReference(formatAccountS3Id("registry")) ]
    [/#if]

    [#assign categoryName = "account"]

[/#if]

[#function getAWSAccountIds accountIds ]
    [#local AWSAccountIds = [] ]

    [#list accountIds as accountId ]
        [#switch accountId]
            [#case "_tenant"]
            [#case "_tenant_"]
            [#case "__tenant__"]
                [#list accounts as id,account ]
                    [#local AWSAccountIds += [ (account.AWSId)!""]  ]
                [/#list]
                [#break]

            [#case "_environment"]
            [#case "_environment_"]
            [#case "__environment__"]
                [#local AWSAccountIds += [ accountObject.AWSId ] ]
                [#break]

            [#case "_global" ]
            [#case "_global_" ]
            [#case "__global__" ]
                [#local AWSAccountIds += [ "*" ]]
                [#break]

            [#default]
                [#local AWSAccountIds += [ (accounts[accountId].AWSId)!"" ]]
        [/#switch]
    [/#list]
    [#return AWSAccountIds ]
[/#function]

[#-- Deployment Profiles --]
[#--  Tenant DeploymentProfiles override standard DeploymentProfiles and Account DeploymentProfiles override this result --]
[#assign deploymentProfiles = {} ]
[#assign tieredDeploymentProfiles = mergeObjects( blueprintObject.DeploymentProfiles, (tenantObject.DeploymentProfiles)!{} ) ]
[#assign tieredDeploymentProfiles = mergeObjects( tieredDeploymentProfiles, (accountObject.DeploymentProfiles)!{} )]

[#list tieredDeploymentProfiles as name,deploymentProfile ]
    [#if deploymentProfile?is_hash ]
        [#list deploymentProfile.Modes as mode,modeProfile ]
            [#if modeProfile?is_hash ]
                [#list modeProfile as type,config ]
                    [#assign deploymentProfiles =
                        mergeObjects(
                            deploymentProfiles,
                            {
                                name : {
                                    "Modes" : {
                                        mode : {
                                            type?lower_case : config
                                        }
                                    }
                                }
                            })]
                [/#list]
            [/#if]
        [/#list]
    [/#if]
[/#list]

[#-- Products --]
[#assign products = (blueprintObject.Products)!{} ]
[#assign productObject = (blueprintObject.Product)!(products[product])!{} ]
[#if productObject?has_content]
    [#assign productId = (productObject.Id!product)!"" ]
    [#assign productName = productObject.Name!productId]
    [#assign products +=
        {
            productId :
                {
                    "Id" : productId,
                    "Name" : productName
                } +
                productObject
        } ]

    [#assign productDomain = productObject.Domain!""]

    [#assign shortNamePrefixes += [productId] ]
    [#assign fullNamePrefixes += [productName] ]
    [#assign cmdbProductLookupPrefixes += ["shared"] ]
    [#assign segmentQualifiers += [productName, productId] ]

[/#if]

[#-- Segments --]
[#assign segments = (blueprintObject.Segments)!{} ]
[#assign segmentObject = (blueprintObject.Segment)!(segments[segment])!{} ]
[#if segmentObject?has_content]
    [#assign segmentId = (segmentObject.Id!segment)!""]
    [#assign segmentName = segmentObject.Name!segmentId]
    [#assign segments +=
        {
            segmentId :
                {
                    "Id" : segmentId,
                    "Name" : segmentName
                } +
                segmentObject
        } ]

    [#if blueprintObject.Environment?? ]
        [#assign environmentId = blueprintObject.Environment.Id ]
        [#assign environmentObject =
            addIdNameToObject(environments[environmentId], environmentId) ]
        [#assign environmentName = environmentObject.Name ]
        [#assign categoryId = segmentObject.Category!environmentObject.Category ]
        [#assign categoryName = categoryId ]
        [#assign categoryObject =
            {
                "Id" : categoryId,
                "Name" : categoryName
            } +
            categories[categoryId] ]

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

    [#-- Cludge for now to get placement profiles working --]
    [#assign placementProfiles =
        (blueprintObject.PlacementProfiles)!{} +
        mergeObjects(
            (productObject.PlacementProfiles)!{},
            (tenantObject.PlacementProfiles)!{}
        ) ]

    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
    [#assign segmentSeed = getExistingReference(formatSegmentSeedId()) ]


        [#assign legacyVpc = getExistingReference(formatVPCId())?has_content ]
        [#if legacyVpc ]
            [#assign vpc = getExistingReference(formatVPCId())]
            [#-- Make sure the baseline component has been added to existing deployments --]
            [#assign segmentSeed = segmentSeed!"COTFatal: baseline component not deployed - Please run a deployment of the baseline component" ]
        [/#if]
    [/#if]

    [#assign network = segmentObject.Network!segmentObject ]

    [#assign internetAccess = network.InternetAccess]

    [#assign natEnabled = internetAccess && ((segmentObject.NAT.Enabled)!true)]
    [#assign natHosted = (segmentObject.NAT.Hosted)!false]

    [#assign rotateKeys = (segmentObject.RotateKeys)!true]

    [#assign sshEnabled = internetAccess &&
                            ((segmentObject.SSH.Enabled)!(segmentObject.Bastion.Enabled)!true)]
    [#assign sshActive = sshEnabled &&
                            ((segmentObject.SSH.Active)!(segmentObject.Bastion.Active)!false)]
    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
        [#assign sshFromProxySecurityGroup = getExistingReference(formatSSHFromProxySecurityGroupId())]
    [/#if]

    [#assign consoleOnly = (segmentObject.ConsoleOnly)!false]

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
            "Enabled" : false
        } ]

    [#if blueprintTier.Components?has_content || ((blueprintTier.Required)!false)]
        [#if (blueprintTier.Network.Enabled)!false ]
            [#list segmentObject.Network.Tiers.Order![] as networkTier]
                [#if networkTier == tierId]
                    [#assign tierNetwork =
                        blueprintTier.Network +
                        {
                            "Index" : networkTier?index,
                            "Link" : addIdNameToObject(blueprintTier.Network.Link, "network")
                        } ]
                    [#break]
                [/#if]
            [/#list]
        [/#if]
        [#assign tiers +=
            [
                addIdNameToObject(blueprintTier, tierId) +
                { "Network" : tierNetwork }
            ] ]
    [/#if]
[/#list]

[#-- Required zones --]
[#assign zones = [] ]
[#list segmentObject.Network.Zones.Order as zoneId]
    [#if regions[commandLineOptions.Regions.Segment].Zones[zoneId]?has_content]
        [#assign zone = regions[commandLineOptions.Regions.Segment].Zones[zoneId] ]
        [#assign zones +=
            [
                addIdNameToObject(zone, zoneId) +
                {
                    "Index" : zoneId?index
                }
            ]
        ]
    [/#if]
[/#list]

[#function getSubnets tier networkResources zoneFilter="" asReferences=true includeZone=false]
    [#local result = [] ]
    [#list networkResources.subnets[tier.Id] as zone, resources]

        [#local subnetId = resources["subnet"].Id ]

        [#local subnetId = asReferences?then(
                                getReference(subnetId),
                                subnetId)]

        [#if (zoneFilter?has_content && zoneFilter == zone) || !zoneFilter?has_content ]
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
        [/#if]
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
                    key :
                        getEffectiveIPAddressGroup(
                            addIdNameToObject(value, key)
                        )
                } ]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#-- Country Groups --]
[@includeSharedReferenceConfiguration referenceType=COUNTRYGROUP_REFERENCE_TYPE /]
[@addReferenceData type=COUNTRYGROUP_REFERENCE_TYPE data=blueprintObject.CountryGroups!{} /]
[#assign countryGroups = (referenceData.CountryGroups)!{} ]

[#-- IP Address Groups - "global" is default --]
[@includeSharedReferenceConfiguration referenceType=IPADDRESSGROUP_REFERENCE_TYPE /]

[#if blueprintObject.IPAddressGroups?has_content ]
    [@addReferenceData type=IPADDRESSGROUP_REFERENCE_TYPE
        data=getEffectiveIPAddressGroups(blueprintObject.IPAddressGroups)
    /]
[/#if]
[#assign ipAddressGroups = referenceData.IPAddressGroups!{} ]

[#function getIPAddressGroup group occurrence={}]
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
                    [#local segmentCIDR += [zoneIP + "/32" ] ]
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

            [#if occurrence?has_content ]

                [#if occurrence.Core.Type == "network" ]
                    [#local networkCIDR = occurrence.Configuration.Solution.Address.CIDR ]
                [#else]
                    [#local occurrenceTier = getTier(occurrence.Core.Tier.Id) ]
                    [#local network = getLinkTarget(occurrence, occurrenceTier.Network.Link, false )]
                    [#local networkCIDR = (network.Configuration.Solution.Address.CIDR)!"COTFatal: local network configuration not found" ]
                [/#if]

                [#return
                {
                    "Id" : groupId,
                    "Name" : groupId,
                    "IsOpen" : false,
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
                        "CIDR" : []
                    } ]
            [/#if]
            [#break]
    [/#switch]
[/#function]

[#function getGroupCIDRs groups checkIsOpen=true occurrence={} asBoolean=false]
    [#local cidrs = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local nextGroup = getIPAddressGroup(group, occurrence) ]
        [#if checkIsOpen && nextGroup.IsOpen!false]
            [#return valueIfTrue(false, asBoolean, ["0.0.0.0/0"]) ]
        [/#if]
        [#local cidrs += nextGroup.CIDR ]
    [/#list]
    [#return valueIfTrue(true, asBoolean, cidrs) ]
[/#function]

[#-- Level utility support --]

[#include "commonApplication.ftl"]
