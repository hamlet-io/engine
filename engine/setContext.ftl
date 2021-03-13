[#ftl]

[#-- Shared Provider Configurations --]
[@includeSharedComponentConfiguration component="shared" /]
[@includeSharedComponentConfiguration component="baseline" /]

[#-- Temporary AWS stuff --]
[#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws") ]
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
[#assign testCases = getReferenceData(TESTCASE_REFERENCE_TYPE) ]
[#assign testProfiles = getReferenceData(TESTPROFILE_REFERENCE_TYPE) ]

[#-- Regions --]
[#assign regions = getReferenceData(REGION_REFERENCE_TYPE) ]

[#-- Categories --]
[#assign categories = getReferenceData(CATEGORY_REFERENCE_TYPE) ]

[#-- Storage Profiles --]
[#assign storage = getReferenceData(STORAGE_REFERENCE_TYPE) ]

[#-- Processor Profiles --]
[#assign processors = getReferenceData(PROCESSOR_REFERENCE_TYPE) ]

[#-- ComputeProvider Profiles --]
[@addReferenceData type=COMPUTEPROVIDER_REFERENCE_TYPE base=blueprintObject /]

[#-- Ports --]
[#assign ports = getReferenceData(PORT_REFERENCE_TYPE) ]

[#-- PortMappings --]
[#assign portMappings = getReferenceData(PORTMAPPING_REFERENCE_TYPE) ]

[#-- Log Files --]
[#assign logFiles = getReferenceData(LOGFILE_REFERENCE_TYPE) ]

[#-- Log File Groups --]
[#assign logFileGroups = getReferenceData(LOGFILEGROUP_REFERENCE_TYPE) ]

[#-- Log File Profiles --]
[#assign logFileProfiles = getReferenceData(LOGFILEPROFILE_REFERENCE_TYPE) ]

[#-- CORS Profiles --]
[#assign CORSProfiles = getReferenceData(CORSPROFILE_REFERENCE_TYPE) ]

[#-- Script Stores --]
[#assign scriptStores = getReferenceData(SCRIPTSTORE_REFERENCE_TYPE) ]

[#-- Bootstraps --]
[#assign bootstraps = getReferenceData(BOOTSTRAP_REFERENCE_TYPE, true) ]

[#-- Bootstrap Profiles--]
[#assign bootstrapProfiles = getReferenceData(BOOTSTRAPPROFILE_REFERENCE_TYPE, true) ]

[#-- Security Profiles --]
[#assign securityProfiles = getReferenceData(SECURITYPROFILE_REFERENCE_TYPE) ]

[#-- Network Profiles --]
[#assign networkProfiles = getReferenceData(NETWORKPROFILE_REFERENCE_TYPE) ]

[#-- Baseline Profiles --]
[#assign baselineProfiles = getReferenceData(BASELINEPROFILE_REFERENCE_TYPE) ]

[#-- Log Filters --]
[#assign logFilters = getReferenceData(LOGFILTER_REFERENCE_TYPE) ]

[#-- Network Endpoint Groups --]
[#assign networkEndpointGroups = getReferenceData(NETWORKENDPOINTGROUP_REFERENCE_TYPE) ]

[#-- WAF --]
[#assign wafProfiles = getReferenceData(WAFPROFILE_REFERENCE_TYPE) ]
[#assign wafRuleGroups = getReferenceData(WAFRULEGROUP_REFERENCE_TYPE) ]
[#assign wafRules = getReferenceData(WAFRULE_REFERENCE_TYPE) ]
[#assign wafConditions = getReferenceData(WAFCONDITION_REFERENCE_TYPE) ]
[#assign wafValueSets = getReferenceData(WAFVALUESET_REFERENCE_TYPE) ]

[#-- Regions --]
[#if commandLineOptions.Regions.Segment?has_content]
    [#assign regionId = commandLineOptions.Regions.Segment]
    [#assign regionObject = (regions[regionId])!{} ]
[/#if]
[#if commandLineOptions.Regions.Account?has_content]
    [#assign accountRegionId = commandLineOptions.Regions.Account]
    [#assign accountRegionObject = (regions[accountRegionId])!{} ]
[/#if]

[#-- Domains --]
[#assign domains =
    addIdNameToObjectAttributes(blueprintObject.Domains!{}) ]

[#-- Certificates --]
[#assign certificates =
    addIdNameToObjectAttributes(blueprintObject.Certificates!{}) ]

[#-- Tenants --]
[#assign tenants = getLayer(TENANT_LAYER_TYPE) ]
[#assign tenantObject = getActiveLayer( TENANT_LAYER_TYPE )]

[#if ((tenantObject.Id)!"")?has_content ]
    [#assign tenantId = tenantObject.Id ]
    [#assign tenantName = tenantObject.Name ]
[/#if]

[#-- Accounts --]
[#assign accounts = getLayer(ACCOUNT_LAYER_TYPE) ]
[#assign accountObject = getActiveLayer(ACCOUNT_LAYER_TYPE)]

[#if ((accountObject.Id)!"")?has_content]
    [#assign accountId = accountObject.Id ]
    [#assign accountName = accountObject.Name ]

    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
        [#assign credentialsBucket = getExistingReference(formatAccountS3Id("credentials"))]
        [#assign credentialsBucketRegion = getExistingReference(formatAccountS3Id("credentials"), REGION_ATTRIBUTE_TYPE)]

        [#assign codeBucket = getExistingReference(formatAccountS3Id("code")) ]
        [#assign codeBucketRegion = getExistingReference(formatAccountS3Id("code"), REGION_ATTRIBUTE_TYPE)]

        [#assign registryBucket = getExistingReference(formatAccountS3Id("registry")) ]
        [#assign registryBucketRegion = getExistingReference(formatAccountS3Id("registry"), REGION_ATTRIBUTE_TYPE)]
    [/#if]

    [#assign categoryName = "account"]

    [#assign operationsExpiration =
                    getActiveLayerAttributes( ["Operations", "Expiration"], [ ACCOUNT_LAYER_TYPE ], "" )[0] ]
[/#if]

[#-- Products --]
[#assign products = getLayer(PRODUCT_LAYER_TYPE) ]
[#assign productObject = getActiveLayer(PRODUCT_LAYER_TYPE) ]

[#if ((productObject.Id)!"")?has_content]
    [#assign productId = productObject.Id ]
    [#assign productName = productObject.Name ]
    [#assign productDomain = productObject.Domain ]

    [#assign shortNamePrefixes += [productId] ]
    [#assign fullNamePrefixes += [productName] ]
    [#assign cmdbProductLookupPrefixes += ["shared"] ]
    [#assign segmentQualifiers += [productName, productId] ]

[/#if]

[#-- Segments --]
[#assign segments = getLayer(SEGMENT_LAYER_TYPE) ]
[#assign segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE)]

[#assign environments = getLayer(ENVIRONMENT_LAYER_TYPE) ]
[#assign environmentObject = getActiveLayer(ENVIRONMENT_LAYER_TYPE) ]

[#if ((segmentObject.Id)!"")?has_content]
    [#assign segmentId = segmentObject.Id ]
    [#assign segmentName = segmentObject.Name ]

    [#if ((environmentObject.Id)!"")?has_content ]
        [#assign environmentId = environmentObject.Id ]
        [#assign environmentName = environmentObject.Name ]

        [#assign categoryId = (segmentObject.Category!environmentObject.Category)!"" ]
        [#assign categoryName = categoryId ]
        [#assign categoryObject =
            {
                "Id" : categoryId,
                "Name" : categoryName
            } +
            categories[categoryId]!{} ]
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

    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
        [#assign segmentSeed = getExistingReference(formatSegmentSeedId()) ]

        [#assign legacyVpc = getExistingReference(formatVPCId())?has_content ]
        [#if legacyVpc ]
            [#assign vpc = getExistingReference(formatVPCId())]
            [#-- Make sure the baseline component has been added to existing deployments --]
            [#assign segmentSeed = segmentSeed!"HamletFatal: baseline component not deployed - Please run a deployment of the baseline component" ]
        [/#if]
    [/#if]

    [#assign rotateKeys = segmentObject.RotateKeys ]

    [#assign network = segmentObject.Network ]
    [#assign internetAccess = network.InternetAccess]

    [#assign natEnabled = internetAccess && segmentObject.NAT.Enabled ]
    [#assign natHosted = segmentObject.NAT.Hosted]

    [#assign sshEnabled = segmentObject.Bastion.Enabled ]
    [#assign sshActive = sshEnabled && segmentObject.Bastion.Active ]

    [#if (commandLineOptions.Deployment.Provider.Names)?seq_contains("aws")]
        [#assign sshFromProxySecurityGroup = getExistingReference(formatSSHFromProxySecurityGroupId())]
    [/#if]

    [#assign operationsExpiration =
                    getActiveLayerAttributes( ["Operations", "Expiration"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

    [#assign operationsOffline =
                    getActiveLayerAttributes( ["Operations", "Offline"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

    [#assign dataExpiration =
                    getActiveLayerAttributes( ["Data", "Expiration"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

    [#assign dataOffline =
                    getActiveLayerAttributes( ["Data", "Offline"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

    [#assign dataPublicEnabled =
                    getActiveLayerAttributes( ["Data", "Public", "Enabled" ], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

    [#assign dataPublicIPAddressGroups =
                    getActiveLayerAttributes( ["Data", "Public", "IPAddressGroups" ], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]

[/#if]

[#-- Solution --]
[#assign solutionObject = getActiveLayer(SOLUTION_LAYER_TYPE) ]
[#if ((solutionObject.Id)!"")?has_content ]
    [#assign solnMultiAZ =
                getActiveLayerAttributes( ["MultiAZ" ], [ SOLUTION_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], false )[0] ]
    [#assign RDSAutoMinorVersionUpgrade =
                getActiveLayerAttributes( ["RDS", "AutoMinorVersionUpgrade" ], [ SEGMENT_LAYER_TYPE, SOLUTION_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], true )[0] ]

    [#assign natPerAZ = natEnabled &&
                        (
                            (natHosted && solnMultiAZ) ||
                            ((segmentObject.NAT.MultiAZ)!false)
                        ) ]
[/#if]

[#function forceProfileComponentTypesToLowerCase profiles]
    [#local result = {} ]
    [#list profiles as name,profile ]
        [#if profile?is_hash ]
            [#list profile.Modes as mode,modeProfile ]
                [#if modeProfile?is_hash ]
                    [#list modeProfile as type,config ]
                        [#local result =
                            mergeObjects(
                                result,
                                {
                                    name : {
                                        "Modes" : {
                                            mode : {
                                                type?lower_case : config
                                            }
                                        }
                                    }
                                }
                            )
                        ]
                    [/#list]
                [/#if]
            [/#list]
        [/#if]
    [/#list]
    [#return result]
[/#function]

[#-- Deployment Profiles use the standard CMDB override mechanism --]
[#-- Deployment profiles for tenant and account are provided for  --]
[#-- backwards compatability                                      --]

[#assign deploymentProfiles =
    forceProfileComponentTypesToLowerCase(
        mergeObjects(
            blueprintObject.DeploymentProfiles!{},
            productObject.DeploymentProfiles!{},
            tenantObject.DeploymentProfiles!{},
            accountObject.DeploymentProfiles!{}
        )
    )
]

[#-- Policy Profiles reflect the desired enforcement hierarchy --]
[#assign policyProfiles =
    forceProfileComponentTypesToLowerCase(
        mergeObjects(
            blueprintObject.PolicyProfiles!{},
            productObject.PolicyProfiles!{},
            accountObject.PolicyProfiles!{},
            tenantObject.PolicyProfiles!{}
        )
    )
]

[#-- Cludge for now to get placement profiles working --]
[#assign placementProfiles =
    (blueprintObject.PlacementProfiles)!{} +
    mergeObjects(
        (productObject.PlacementProfiles)!{},
        (tenantObject.PlacementProfiles)!{}
    ) ]

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
    [#if ((regions[commandLineOptions.Regions.Segment].Zones[zoneId])!"")?has_content]
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

[#-- Validate Deployment Info --]
[#if ((commandLineOptions.Deployment.Mode)!"")?has_content ]
    [#if ! getDeploymentMode()?has_content ]
        [@fatal
            message="Undefined deployment mode used"
            detail="Could not find definition of provided DeploymentMode"
            context={ "DeploymentMode" : commandLineOptions.Deployment.Mode }
        /]
    [/#if]
[/#if]

[#if ((commandLineOptions.Deployment.Group.Name)!"")?has_content ]
    [#if ! getDeploymentGroup()?has_content ]
        [@fatal
            message="Undefined deployment group used"
            detail="Could not find definition of provided DeploymentGroup"
            context={ "DeploymentGroup" : commandLineOptions.Deployment.Group.Name }
        /]
    [/#if]
[/#if]

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

[#-- Provider Account Query --]
[#function getProviderAccountIds accountIds ]
    [#local ProviderAccountIds = [] ]

    [#list accountIds as accountId ]
        [#switch accountId]
            [#case "_tenant"]
            [#case "_tenant_"]
            [#case "__tenant__"]
                [#list accounts as id,account ]
                    [#local ProviderAccountIds += [ (account.ProviderId)!""]  ]
                [/#list]
                [#break]

            [#case "_environment"]
            [#case "_environment_"]
            [#case "__environment__"]
                [#local ProviderAccountIds += [ accountObject.ProviderId ] ]
                [#break]

            [#case "_global" ]
            [#case "_global_" ]
            [#case "__global__" ]
                [#local ProviderAccountIds += [ "*" ]]
                [#break]

            [#default]
                [#local ProviderAccountIds += [ (accounts[accountId].ProviderId)!"" ]]
        [/#switch]
    [/#list]
    [#return ProviderAccountIds ]
[/#function]

[#-- Country Groups --]
[#assign countryGroups = getReferenceData(COUNTRYGROUP_REFERENCE_TYPE, true) ]

[#-- IP Address Groups - "global" is default --]
[#if blueprintObject.IPAddressGroups?has_content ]
    [@addReferenceData type=IPADDRESSGROUP_REFERENCE_TYPE
        data=getEffectiveIPAddressGroups(blueprintObject.IPAddressGroups)
    /]
[/#if]
[#assign ipAddressGroups = getReferenceData(IPADDRESSGROUP_REFERENCE_TYPE, true) ]

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

[#function getIPAddressGroup group occurrence={}]
    [#local groupId = group?is_hash?then(group.Id, group) ]

    [#if groupId?starts_with("_tier") || groupId?starts_with("__tier") ]
        [#local lookupTier = groupId?split(":")[1] ]
        [#if ! lookupTier?has_content ]
            [@fatal
                message="Invalid Tier IP AddressGroup"
                detail="Please provide tier groups as _tier:tierId"
                context=groupId
            /]

            [#return
                {
                    "Id" : groupId,
                    "IsOpen" : true,
                    "IsLocal" : false,
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
                    [#local tierSubnets += [ resource.subnet.Address ] ]
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

[#function getGroupCIDRs groups checkIsOpen=true occurrence={} asBoolean=false]
    [#local cidrs = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local nextGroup = getIPAddressGroup(group, occurrence) ]
        [#if checkIsOpen && nextGroup.IsOpen!false]
            [#return valueIfTrue(false, asBoolean, ["0.0.0.0/0"]) ]
        [/#if]
        [#local cidrs += nextGroup.CIDR ]
    [/#list]
    [#return valueIfTrue(cidrs?has_content, asBoolean, cidrs) ]
[/#function]

[#function getGroupCountryCodes groups blacklist=false]
    [#local codes = [] ]
    [#list asFlattenedArray(groups) as group]
        [#local groupEntry = (countryGroups[group])!{}]
        [#if (groupEntry.Blacklist!false) == blacklist ]
            [#local codes += asArray(groupEntry.Locations![]) ]
        [/#if]
    [/#list]
    [#return codes]
[/#function]


[#-- Level utility support --]

[#include "commonApplication.ftl"]
