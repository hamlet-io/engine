[#ftl]

[#-- Shared Provider Configurations --]
[@includeSharedComponentConfiguration component="shared" /]
[@includeSharedComponentConfiguration component="baseline" /]
[@includeSharedComponentConfiguration component="s3" /]
[@includeSharedComponentConfiguration component="ec2" /]

[#-- Temporary AWS stuff --]
[#if getLoaderProviders()?seq_contains("aws") ]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="baseline" /]
    [@includeProviderComponentConfiguration provider="aws" component="baseline" services="baseline" /]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="s3" /]
    [@includeProviderComponentConfiguration provider="aws" component="s3" services="s3" /]
    [@includeProviderComponentDefinitionConfiguration provider="aws" component="ec2" /]
    [@includeProviderComponentConfiguration provider="aws" component="ec2" services=["ec2", "vpc"] /]
[/#if]

[#-- Temporary function to permit a transition away from global variables --]
[#-- The only use of this should be in invokeExtensions to support        --]
[#-- a period where all extensions and fragments are switched to the      --]
[#-- accessor functions. All other uses should be converted to accessors. --]

[#macro populateSetContextGlobalVariables enabled]

    [#local providerIsKnown = (.vars["getExistingReference"]!"")?is_directive ]

    [#if providerIsKnown && enabled]
        [#assign credentialsBucket = getCredentialsBucket() ]
        [#assign credentialsBucketRegion = getCredentialsBucketRegion() ]

        [#assign codeBucket = getCodeBucket() ]
        [#assign codeBucketRegion = getCodeBucketRegion() ]

        [#assign registryBucket = getRegistryBucket() ]
        [#assign registryBucketRegion = getRegistryBucketRegion() ]

        [#assign vpc = getVpc() ]
        [#assign legacyVpc = getLegacyVpc() ]

        [#assign segmentSeed = getSegmentSeed() ]

        [#assign sshFromProxySecurityGroup = getSshFromProxySecurityGroup() ]

        [#assign regions = getRegions() ]

        [#assign regionId = getRegion() ]
        [#assign regionObject = getRegionObject() ]

        [#assign accountRegionId = getAccountRegion() ]
        [#assign accountRegionObject = getAccountRegionObject() ]

        [#assign tiers = getTiers() ]
        [#assign zones = getZones() ]
    [/#if]

[/#macro]

[#-- Account level buckets --]
[#function getCredentialsBucket]
    [#return getExistingReference(formatAccountS3Id("credentials")) ]
[/#function]

[#function getCredentialsBucketRegion]
    [#return getExistingReference(formatAccountS3Id("credentials"), REGION_ATTRIBUTE_TYPE) ]
[/#function]

[#function getCodeBucket]
    [#return getExistingReference(formatAccountS3Id("code")) ]
[/#function]

[#function getCodeBucketRegion]
    [#return getExistingReference(formatAccountS3Id("code"), REGION_ATTRIBUTE_TYPE)]
[/#function]

[#function getRegistryBucket]
    [#return getExistingReference(formatAccountS3Id("registry")) ]
[/#function]

[#function getRegistryBucketRegion]
    [#return getExistingReference(formatAccountS3Id("registry"), REGION_ATTRIBUTE_TYPE)]
[/#function]

[#-- Network --]
[#function getVpc]
    [#return getExistingReference(formatVPCId()) ]
[/#function]

[#function getLegacyVpc]
    [#return getVpc()?has_content ]
[/#function]

[#-- Segment Seed --]
[#function getSegmentSeed]
    [#local seed = getExistingReference(formatSegmentSeedId()) ]

        [#if getLegacyVpc() && (!seed?has_content)]
            [#-- Make sure the baseline component has been added to existing deployments --]
            [#local seed = "HamletFatal: baseline component not deployed - Please run a deployment of the baseline component" ]
        [/#if]
    [#return seed]
[/#function]

[#-- SSH --]
[#function getSshFromProxySecurityGroup]
    [#return getExistingReference(formatSSHFromProxySecurityGroupId()) ]
[/#function]

[#-- Regions --]
[#function getRegions]
    [#return getReferenceData(REGION_REFERENCE_TYPE) ]
[/#function]

[#function getRegion]
    [#local result = ""]

    [#if getCLOSegmentRegion()?has_content || getProductLayerRegion()?has_content]
        [#local result = getCLOSegmentRegion()]
        [#if ! result?has_content]
            [#local result = getProductLayerRegion() ]
        [/#if]
    [/#if]

    [#return result]
[/#function]

[#function getRegionObject region="" ]
    [#return (getRegions()[contentIfContent( region, getRegion() ) ])!{} ]
[/#function]

[#function getAccountRegion]
    [#local result = ""]

    [#if getCLOAccountRegion()?has_content || getAccountLayerRegion()?has_content ]
        [#local result = getCLOAccountRegion()]
        [#if ! result?has_content]
            [#local result = getAccountLayerRegion() ]
        [/#if]
    [/#if]

    [#return result]
[/#function]

[#function getAccountRegionObject region="" ]
    [#return (getRegions()[contentIfContent( region, getAccountRegion() ) ])!{} ]
[/#function]

[#-- Active tiers --]
[#function getTiers]
    [#local result = [] ]

    [#if isLayerActive(SEGMENT_LAYER_TYPE) ]
        [#local blueprintTiers = getBlueprint().Tiers!{} ]
        [#local segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE) ]

        [#list segmentObject.Tiers.Order as tierId]
            [#local blueprintTier = (blueprintTiers[tierId])!{} ]
            [#if ! (blueprintTier?has_content) ]
                [#continue]
            [/#if]
            [#local tierNetwork =
                {
                    "Enabled" : false
                } ]

            [#if blueprintTier.Components?has_content || ((blueprintTier.Required)!false)]
                [#if (blueprintTier.Network.Enabled)!false ]
                    [#list segmentObject.Network.Tiers.Order![] as networkTier]
                        [#if networkTier == tierId]
                            [#local tierNetwork =
                                blueprintTier.Network +
                                {
                                    "Index" : networkTier?index,
                                    "Link" : addIdNameToObject(blueprintTier.Network.Link, "network")
                                } ]
                            [#break]
                        [/#if]
                    [/#list]
                [/#if]
                [#local result +=
                    [
                        addIdNameToObject(blueprintTier, tierId) +
                        { "Network" : tierNetwork }
                    ] ]
            [/#if]
        [/#list]
    [/#if]

    [#return result]
[/#function]

[#-- Active zones --]
[#function getZones]
    [#local result = [] ]

    [#local regions = getRegions() ]
    [#local regionId = getRegion() ]

    [#if isLayerActive(SEGMENT_LAYER_TYPE) ]
        [#local segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE) ]

        [#if regionId?has_content]
            [#list segmentObject.Network.Zones.Order as zoneId]
                [#if ((regions[regionId].Zones[zoneId])!"")?has_content]
                    [#local zone = regions[regionId].Zones[zoneId] ]
                    [#local result +=
                        [
                            addIdNameToObject(zone, zoneId) +
                            {
                                "Index" : zoneId?index
                            }
                        ]
                    ]
                [/#if]
            [/#list]
        [/#if]
    [/#if]

    [#return result]
[/#function]

[#macro setContext]

    [#assign blueprintObject = getBlueprint() ]

    [#-- Load reference data for any references defined by providers --]
    [@includeReferences blueprintObject /]

    [#-- Name prefixes --]
    [#assign shortNamePrefixes = [] ]
    [#assign fullNamePrefixes = [] ]
    [#assign cmdbProductLookupPrefixes = [] ]

    [#-- Testing --]
    [#assign testCases = getReferenceData(TESTCASE_REFERENCE_TYPE) ]
    [#assign testProfiles = getReferenceData(TESTPROFILE_REFERENCE_TYPE) ]

    [#-- Regions --]
    [#assign regions = getReferenceData(REGION_REFERENCE_TYPE) ]

    [#-- Categories --]
    [#assign categories = getReferenceData(CATEGORY_REFERENCE_TYPE) ]

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

    [#-- CORS Profiles --]
    [#assign CORSProfiles = getReferenceData(CORSPROFILE_REFERENCE_TYPE) ]

    [#-- Script Stores --]
    [#assign scriptStores = getReferenceData(SCRIPTSTORE_REFERENCE_TYPE) ]

    [#-- Bootstraps --]
    [#assign bootstraps = getReferenceData(BOOTSTRAP_REFERENCE_TYPE, true) ]

    [#-- Log Filters --]
    [#assign logFilters = getReferenceData(LOGFILTER_REFERENCE_TYPE) ]

    [#-- Baseline Profiles --]
    [#assign baselineProfiles = getReferenceData(BASELINEPROFILE_REFERENCE_TYPE) ]

    [#-- Network Endpoint Groups --]
    [#assign networkEndpointGroups = getReferenceData(NETWORKENDPOINTGROUP_REFERENCE_TYPE) ]

    [#-- WAF --]
    [#assign wafProfiles = getReferenceData(WAFPROFILE_REFERENCE_TYPE) ]
    [#assign wafRuleGroups = getReferenceData(WAFRULEGROUP_REFERENCE_TYPE) ]
    [#assign wafRules = getReferenceData(WAFRULE_REFERENCE_TYPE) ]
    [#assign wafConditions = getReferenceData(WAFCONDITION_REFERENCE_TYPE) ]
    [#assign wafValueSets = getReferenceData(WAFVALUESET_REFERENCE_TYPE) ]

    [#-- Domains --]
    [#assign domains =
        addIdNameToObjectAttributes(blueprintObject.Domains!{}) ]

    [#-- Certificates --]
    [#assign certificates =
        addIdNameToObjectAttributes(blueprintObject.Certificates!{}) ]

    [#-- Tenants --]
    [#if isLayerActive(TENANT_LAYER_TYPE) ]
        [#-- assign tenants = getLayer(TENANT_LAYER_TYPE) --]
        [#assign tenantObject = getActiveLayer( TENANT_LAYER_TYPE )]

        [#assign tenantId = tenantObject.Id ]
        [#assign tenantName = tenantObject.Name ]
    [/#if]

    [#-- Accounts --]
    [#if isLayerActive(ACCOUNT_LAYER_TYPE) ]
        [#-- assign accounts = getLayer(ACCOUNT_LAYER_TYPE) --]
        [#assign accountObject = getActiveLayer(ACCOUNT_LAYER_TYPE)]

        [#assign accountId = accountObject.Id ]
        [#assign accountName = accountObject.Name ]

        [#-- Cludge for now until access to reference data is reworked --]
        [#-- TODO(mfl): revisit with a view to remove --]
        [#assign accounts = {accountId : accountObject} ]

        [#assign categoryName = "account"]

        [#assign operationsExpiration =
                        getActiveLayerAttributes( ["Operations", "Expiration"], [ ACCOUNT_LAYER_TYPE ], "" )[0] ]
    [/#if]

    [#-- Products --]
    [#if isLayerActive(PRODUCT_LAYER_TYPE) ]
        [#-- assign products = getLayer(PRODUCT_LAYER_TYPE) --]
        [#assign productObject = getActiveLayer(PRODUCT_LAYER_TYPE) ]

        [#assign productId = (productObject.Id)!"" ]
        [#assign productName = (productObject.Name)!"" ]
        [#assign productDomain = productObject.Domain!"" ]

        [#assign shortNamePrefixes += [productId] ]
        [#assign fullNamePrefixes += [productName] ]
        [#assign cmdbProductLookupPrefixes += ["shared"] ]
    [/#if]

    [#-- Segments --]
    [#if isLayerActive(SEGMENT_LAYER_TYPE) ]
        [#-- assign segments = getLayer(SEGMENT_LAYER_TYPE) --]
        [#assign segmentObject = getActiveLayer(SEGMENT_LAYER_TYPE)]

        [#assign segmentId = (segmentObject.Id)!"" ]
        [#assign segmentName = (segmentObject.Name)!"" ]

        [#if isLayerActive(ENVIRONMENT_LAYER_TYPE) ]
            [#-- assign environments = getLayer(ENVIRONMENT_LAYER_TYPE) --]
            [#assign environmentObject = getActiveLayer(ENVIRONMENT_LAYER_TYPE) ]

            [#assign environmentId = (environmentObject.Id)!"" ]
            [#assign environmentName = (environmentObject.Name)!"" ]

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

        [#assign rotateKeys = segmentObject.RotateKeys ]

        [#assign network = segmentObject.Network ]
        [#assign internetAccess = network.InternetAccess]

        [#assign natEnabled = internetAccess && segmentObject.NAT.Enabled ]
        [#assign natHosted = segmentObject.NAT.Hosted]

        [#assign sshEnabled = segmentObject.Bastion.Enabled ]
        [#assign sshActive = sshEnabled && segmentObject.Bastion.Active ]

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

        [#assign flowlogsExpiration =
                        getActiveLayerAttributes( ["Operations", "FlowLogs", "Expiration"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], 7 )[0] ]

        [#assign flowlogsOffline =
                        getActiveLayerAttributes( ["Operations", "FlowLogs", "Offline"], [ SEGMENT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ], "" )[0] ]
    [/#if]

    [#-- Solution --]
    [#if isLayerActive(SOLUTION_LAYER_TYPE) ]
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

        [#else]
            [#-- Handle global vars when solution is not defined --]
            [#assign solnMultiAZ = false]
            [#assign RDSAutoMinorVersionUpgrade = false]
            [#assign natPerAZ = false]
        [/#if]
    [/#if]

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

    [#-- Country Groups --]
    [#assign countryGroups = getReferenceData(COUNTRYGROUP_REFERENCE_TYPE, true) ]

    [#-- IP Address Groups - "global" is default --]
    [#if blueprintObject.IPAddressGroups?has_content ]
        [@addReferenceData type=IPADDRESSGROUP_REFERENCE_TYPE
            data=getEffectiveIPAddressGroups(blueprintObject.IPAddressGroups)
        /]
    [/#if]
    [#assign ipAddressGroups = getReferenceData(IPADDRESSGROUP_REFERENCE_TYPE, true) ]
[/#macro]

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
            [#list getZones() as zone]
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
