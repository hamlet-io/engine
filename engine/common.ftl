[#ftl]

[#-- Check if a deployment unit occurs anywhere in provided object --]
[#function getDeploymentUnitId obj]
    [#if obj["deployment:Unit"]?has_content ]
        [#return obj["deployment:Unit"]]
    [#else]
        [#if ! obj.DeploymentUnits?has_content ]
            [#return ""]
        [/#if]

        [#return (((obj.DeploymentUnits)![])[0])!"" ]
    [/#if]
[/#function]

[#function deploymentRequired obj unit group="" deploymentGroupOverride="" subObjects=true includeGroupMembership=false ]
    [#if obj?is_hash]
        [#if allDeploymentUnits!false]
            [#return true]
        [/#if]
        [#if !unit?has_content]
            [#return true]
        [/#if]

        [#local unitDeploymentGroup = (obj["deployment:Group"])!deploymentGroupOverride ]

        [#if groupDeploymentUnits!false ]
            [#if unitDeploymentGroup == group  ]
                [#return true]
            [/#if]
        [/#if]

        [#if getDeploymentUnitId(obj)?has_content && getDeploymentUnitId(obj) == unit ]
            [#if includeGroupMembership ]
                [#if unitDeploymentGroup == group || group == "*" ]
                    [#return true ]
                [/#if]
            [#else]
                [#return true]
            [/#if]
        [/#if]
        [#if subObjects]
            [#list obj?values as attribute]
                [#if deploymentRequired(attribute, unit, group, deploymentGroupOverride, subObjects, includeGroupMembership)]
                    [#return true]
                [/#if]
            [/#list]
        [/#if]
    [/#if]
    [#return false]
[/#function]

[#function requiredOccurrences occurrences deploymentUnit deploymentGroup deploymentGroupOverride="" checkSubOccurrences=false]
    [#local result = [] ]
    [#list asFlattenedArray(occurrences) as occurrence]
        [#-- Ignore if not enabled --]
        [#if (occurrence.Configuration.Solution.Enabled)!false]
            [#-- Is the occurrence required --]
            [#if deploymentRequired(occurrence.Configuration.Solution, deploymentUnit, deploymentGroup, deploymentGroupOverride, false, true )]
                [#local result += [occurrence] ]
                [#continue]
            [/#if]
            [#-- is a suboccurrence required --]
            [#if checkSubOccurrences &&
                occurrence.Occurrences?has_content &&
                requiredOccurrences(occurrence.Occurrences, deploymentUnit, deploymentGroup, (occurrence.Configuration.Solution["deployment:Group"])!"",  true)?has_content]
                [#local result += [occurrence] ]
                [#continue]
            [/#if]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function deploymentSubsetRequired subset default=false]

    [#local selectedSubset = getCLODeploymentUnitSubset() ]
    [#return
        selectedSubset?has_content?then(
            selectedSubset?lower_case?contains(subset),
            default
        )]
[/#function]

[#-- S3 settings/appdata storage  --]

[#function getSettingsFilePrefix occurrence ]
    [#return formatRelativePath("settings", occurrence.Core.FullRelativePath) ]
[/#function]

[#function getAppDataFilePrefix occurrence={} ]
    [#if occurrence?has_content]
        [#local override =
            getOccurrenceSettingValue(
                occurrence,
                [
                    ["FilePrefixes", "AppData"],
                    ["DefaultFilePrefix"]
                ], true) ]
        [#return
            formatRelativePath(
                "appdata",
                valueIfContent(
                    formatSegmentRelativePath(override),
                    override,
                    occurrence.Core.FullRelativePath
                )
            ) ]
    [#else]
        [#return _context.Environment["APPDATA_PREFIX"] ]
    [/#if]
[/#function]

[#function getAppDataPublicFilePrefix occurrence={} ]
    [#if segmentObject.Data.Public.Enabled ]
        [#if occurrence?has_content]
            [#local override =
                getOccurrenceSettingValue(
                    occurrence,
                    [
                        ["FilePrefixes", "AppPublic"],
                        ["FilePrefixes", "AppData"],
                        ["DefaultFilePrefix"]
                    ], true) ]
            [#return
                formatRelativePath(
                    "apppublic",
                    valueIfContent(
                        formatSegmentRelativePath(override),
                        override,
                        occurrence.Core.FullRelativePath
                    )
                ) ]
        [#else]
            [#return _context.Environment["APPDATA_PUBLIC_PREFIX"] ]
        [/#if]
    [#else]
        [#return ""]
    [/#if]
[/#function]

[#function getBackupsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return formatRelativePath("backups", occurrence.Core.FullRelativePath) ]
    [#else]
        [#return _context.Environment["BACKUPS_PREFIX"] ]
    [/#if]
[/#function]

[#-- Legacy functions - appsettings and credentials now treated the same --]
[#-- These were required in container fragments before permissions were  --]
[#-- automatically added.                                                --]

[#function getCredentialsFilePrefix occurrence={} ]
    [#if occurrence?has_content ]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return _context.Environment["SETTINGS_PREFIX"] ]
    [/#if]
[/#function]

[#function getAppSettingsFilePrefix occurrence={} ]
    [#if occurrence?has_content]
        [#return getSettingsFilePrefix(occurrence) ]
    [#else]
        [#return _context.Environment["SETTINGS_PREFIX"] ]
    [/#if]
[/#function]

[#-- End legacy functions --]

[#function getSegmentCredentialsFilePrefix  ]
    [#return formatSegmentPrefixPath("credentials")]
[/#function]

[#function getSegmentAppSettingsFilePrefix  ]
    [#return formatSegmentPrefixPath("appsettings")]
[/#function]

[#function getSegmentAppDataFilePrefix ]
    [#return formatSegmentPrefixPath("appdata")]
[/#function]

[#function getSegmentBackupsFilePrefix ]
    [#return formatSegmentPrefixPath("backups")]
[/#function]



[#-- Zones --]

[#-- Get the id for a zone --]
[#function getZoneId zone]
    [#if zone?is_hash]
        [#return zone.Id]
    [#else]
        [#return zone]
    [/#if]
[/#function]

[#-- Get the name for a zone --]
[#function getZoneName zone]
    [#if zone?is_hash]
        [#return zone.Name]
    [#else]
        [#return zone]
    [/#if]
[/#function]

[#function getOccurrenceCoreTags occurrence={} name="" zone="" propagate=false flatten=false maxTagCount=-1]
    [#return getCfTemplateCoreTags(name, (occurrence.Core.Tier)!"", (occurrence.Core.Component)!"", zone, propagate, flatten, maxTagCount)]
[/#function]

[#-- Get processor settings --]
[#function getOccurrenceProfile occurrence solutionProfilesKey profileReferenceType profileNameOverride="" type="" ]
    [#local profileName = ""]
    [#if profileNameOverride?has_content]
        [#local profileName = profileNameOverride ]
    [/#if]

    [#if ! profileName?has_content ]
        [#if ((occurrence.Configuration.Solution.Profiles[solutionProfilesKey])!"")?has_content ]
            [#local profileName = occurrence.Configuration.Solution.Profiles[solutionProfilesKey] ]
        [#else]
            [@fatal
                message="Could not find profile name to use for lookup"
                context={
                    "OccurrenceId" : (occurrence.Core.RawId)!"",
                    "ProfileKey" : solutionProfilesKey,
                    "NameOverride" : profileNameOverride,
                    "Type" : type
                }
            /]
        [/#if]
    [/#if]

    [#local profile = (getReferenceData(profileReferenceType)[profileName])!{} ]

    [#-- we have two types of profiles --]
    [#-- Typed - provides a profile for each compoent type under a single profile --]
    [#-- Fixed - isn't type based and just returns the resolved profile --]
    [#if type?has_content ]
        [#local tc = formatComponentShortName(occurrence.Core.Tier.Id, occurrence.Core.Component.Id)]
        [#list profile as key,value ]
            [#switch key?lower_case ]
                [#case tc?lower_case ]
                    [#return profile[key]]
                    [#break]
                [#case type?lower_case]
                    [#return profile[key]]
                    [#break]
            [/#switch]
        [/#list]
    [/#if]

    [#if ! profile?has_content ]
        [@fatal
            message="requested profile not found"
            detail={
                "OccurrenceId" : (occurrence.Core.RawId)!"",
                "SolutionProfile" : solutionProfilesKey,
                "ReferenceType" : profileReferenceType,
                "NameOverride" : profileNameOverride,
                "Name" : profileName,
                "Type" : type
            }
        /]
    [/#if]
    [#return profile]
[/#function]

[#function getProcessor occurrence type profileName="" ]
    [#return getOccurrenceProfile(occurrence, "Processor", PROCESSOR_REFERENCE_TYPE, profileName, type)]
[/#function]

[#function getProcessorCounts processorProfile multiAz=false desiredCount="" minCount="" maxCount="" ]

    [#local fixedMaxCount = maxCount?has_content?then(
                                maxCount,
                                (processorProfile.MaxCount)!""
                            )]

    [#local fixedMinCount = minCount?has_content?then(
                                minCount,
                                (processorProfile.MinCount)!""
                            )]

    [#local fixedDesiredCount = desiredCount?has_content?then(
                                    desiredCount,
                                    (processorProfile.DesiredCount)!""
                                )]

    [#if fixedMaxCount?has_content ]
        [#local maxCount = fixedMaxCount ]
    [#elseif processorProfile.MaxPerZone?has_content ]
        [#local maxCount = processorProfile.MaxPerZone ]
        [#if multiAZ]
            [#local maxCount = maxCount * getZones()?size]
        [/#if]
    [#else]
        [@fatal
            message="Processor profile does not have a MaxCount"
            context=processorProfile
        /]
    [/#if]

    [#if fixedMinCount?has_content ]
        [#local minCount = fixedMinCount ]
    [#elseif processorProfile.MinPerZone?has_content ]
        [#local minCount = (processorProfile.MinPerZone)!1]
        [#if multiAZ]
            [#local minCount = minCount * getZones()?size]
        [/#if]
    [#else]
        [@fatal
            message="Processor profile does not have a MinCount"
            context=processorProfile
        /]
    [/#if]

    [#if fixedDesiredCount?has_content ]
        [#local desiredCount = fixedDesiredCount ]
    [#elseif processorProfile.DesiredPerZone?has_content ]
        [#local desiredCount = (processorProfile.DesiredPerZone)!1 ]
        [#if multiAZ]
            [#local desiredCount = desiredCount * getZones()?size]
        [/#if]
    [#else]
        [@fatal
            message="Processor profile does not have a DesiredCount"
            context=processorProfile
        /]
    [/#if]

    [#return
        {
            "MaxCount"      : maxCount?has_content?then(maxCount?number, 0 ),
            "MinCount"      : minCount?has_content?then(minCount?number, 0 ),
            "DesiredCount"  : desiredCount?has_content?then(desiredCount?number, 0 )
        }
    ]
[/#function]

[#-- Get storage settings --]
[#function getStorage occurrence type profileName="" ]
    [#return getOccurrenceProfile(occurrence, "Storage", STORAGE_REFERENCE_TYPE, profileName, type)]
[/#function]

[#function getLogFileProfile occurrence type profileName="" ]
    [#return getOccurrenceProfile(occurrence, "LogFile", LOGFILEPROFILE_REFERENCE_TYPE, profileName, type)]
[/#function]

[#function getBootstrapProfile occurrence type profileName="" ]
    [#return getOccurrenceProfile(occurrence, "Bootstrap", BOOTSTRAPPROFILE_REFERENCE_TYPE, profileName, type)]
[/#function]

[#function getSecurityProfile occurrence type engine="" profileName="" ]
    [#local baseProfile = getOccurrenceProfile(occurrence, "Security", SECURITYPROFILE_REFERENCE_TYPE, profileName, type)]
    [#return (baseProfile[engine])!baseProfile ]
[/#function]

[#function getNetworkProfile occurrence profileName=""  ]
    [#return getOccurrenceProfile(occurrence, "Network", NETWORKPROFILE_REFERENCE_TYPE, profileName) ]
[/#function]

[#function getComputeProviderProfile occurrence profileName=""  ]
    [#return getOccurrenceProfile(occurrence, "ComputeProvider", COMPUTEPROVIDER_REFERENCE_TYPE, profileName) ]
[/#function]

[#function getLoggingProfile occurrence profileName=""  ]
    [#return getOccurrenceProfile(occurrence, "Logging", LOGGINGPROFILE_REFERENCE_TYPE, profileName) ]
[/#function]

[#function getNetworkEndpoints endpointGroups zone region ]
    [#local services = []]
    [#local networkEndpoints = {}]

    [#local regionObject = getRegions()[region]]
    [#local zoneNetworkEndpoints = (regionObject.Zones[zone].NetworkEndpoints)![] ]

    [#list endpointGroups as endpointGroup ]
        [#if networkEndpointGroups[endpointGroup]?? ]
            [#list networkEndpointGroups[endpointGroup].Services as service ]
                [#if !services?seq_contains(service) ]
                    [#local services += [ service ]]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#list services as service ]
        [#list zoneNetworkEndpoints as zoneNetworkEndpoint ]
            [#if (zoneNetworkEndpoint.ServiceName!"")?ends_with(service) ]
                [#local networkEndpoints +=
                    {
                        service : zoneNetworkEndpoint
                    }]
            [/#if]
        [/#list]
    [/#list]

    [#return networkEndpoints]
[/#function]


[#-- Deployment/Policy Profiles --]

[#assign deploymentProfileConfiguration = [
    {
        "Names" : "Modes",
        "Description" : "A nested object with the deployment mode name as the root and childs based on component types",
        "Types" : OBJECT_TYPE
    }
]]

[#function getDeploymentProfile occurrenceProfiles deploymentMode ]

    [#-- Get the total list of deployment profiles --]
    [#local deploymentProfileNames =
        getUniqueArrayElements(
            (tenantObject.Profiles.Deployment)![],
            (accountObject.Profiles.Deployment)![],
            (productObject.Profiles.Deployment)![],
            (environmentObject.Profiles.Deployment)![],
            (segmentObject.Profiles.Deployment)![],
            occurrenceProfiles
        ) ]

    [#local deploymentProfile = {} ]
    [#list deploymentProfileNames as deploymentProfileName ]
        [#local deploymentProfile = mergeObjects( deploymentProfile, (deploymentProfiles[deploymentProfileName])!{} )]
    [/#list]

    [#return mergeObjects( (deploymentProfile.Modes["*"])!{}, (deploymentProfile.Modes[deploymentMode])!{})  ]
[/#function]

[#function getPolicyProfile occurrencePolicies deploymentMode ]

    [#-- Get the total list of deployment profiles --]
    [#local policyProfileNames =
        getUniqueArrayElements(
            occurrencePolicies,
            (segmentObject.Profiles.Policy)![],
            (environmentObject.Profiles.Policy)![],
            (productObject.Profiles.Policy)![],
            (accountObject.Profiles.Policy)![],
            (tenantObject.Profiles.Policy)![]
        ) ]

    [#local policyProfile = {} ]
    [#list policyProfileNames as policyProfileName ]
        [#local policyProfile = mergeObjects( policyProfile, (policyProfiles[policyProfileName])!{} )]
    [/#list]

    [#return mergeObjects( (policyProfile.Modes["*"])!{}, (policyProfile.Modes[deploymentMode])!{})  ]
[/#function]


[#-- Placement Profiles --]
[#assign placementProfileConfiguration = [
    {
        "Names" : "*",
        "Children"  : [
            {
                "Names" : "Provider",
                "Description" : "The provider to use to host the component",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "Region",
                "Description" : "The id of the region to host the component",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "DeploymentFramework",
                "Description" : "The deployment framework to use to generate the outputs for deployment",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            }
        ]
    }
]]

[#function getPlacementProfile occurrenceProfile]
    [#local profile = occurrenceProfile]
    [#if !profile?has_content]
        [#local profile = (productObject.Profiles.Placement)!""]
    [/#if]
    [#if !profile?has_content]
        [#local profile = (tenantObject.Profiles.Placement)!""]
    [/#if]
    [#if !profile?has_content]
        [#local profile = DEFAULT_PLACEMENT_PROFILE]
    [/#if]

    [#if profile?is_hash]
        [#local profile = ""]
    [/#if]

    [#return placementProfiles[profile]!{} ]
[/#function]

[#--Certificate/Domain Name handling --]

[#assign certificateBehaviourConfiguration = [
        {
            "Names" : "External",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Domain",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "IncludeInDomain",
            "Children" : [
                {
                    "Names" : "Product",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Environment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Segment",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        },
        {
            "Names" : "Host",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "IncludeInHost",
            "Children" : [
                {
                    "Names" : "Product",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Environment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Segment",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Tier",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Component",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Instance",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Version",
                    "Types" : BOOLEAN_TYPE
                },
                {
                    "Names" : "Host",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        },
        {
            "Names" : "HostParts",
            "Types" : ARRAY_OF_STRING_TYPE
        }
    ]
]

[#-- Primary is used on component attributes --]
[#assign DOMAIN_ROLE_PRIMARY="primary" ]

[#-- Secondaries allow a smooth transition from one domain to another --]
[#assign DOMAIN_ROLE_SECONDARY="secondary" ]

[#-- Names --]
[#function formatHostDomainName host parts style=""]
    [#local result =
        formatDomainName(
            formatName(host),
            parts
        )]
    [#switch style]
        [#case "hyphenated"]
            [#return result?replace(".", "-")]
            [#break]
        [#default]
            [#return result]
    [/#switch]

[/#function]

[#-- Resources --]
[#function isPrimaryDomain domainObject]
    [#return domainObject.Role == DOMAIN_ROLE_PRIMARY ]
[/#function]

[#function isSecondaryDomain domainObject]
    [#return domainObject.Role == DOMAIN_ROLE_SECONDARY ]
[/#function]

[#function getDomainObjects certificateObject ]
    [#local result = [] ]
    [#local primaryNotSeen = true]
    [#local lines = getObjectLineage(domains, (certificateObject.Domain)!"") ]
    [#list lines as line]
        [#local name = "" ]
        [#local role = DOMAIN_ROLE_PRIMARY ]
        [#list line as domainObject]
            [#local qualifiedDomainObject =
                getCompositeObject(
                    domainChildConfiguration,
                    domainObject
                )]
            [#if !(qualifiedDomainObject.Bare) ]
                [#local name = formatDomainName(
                                   contentIfContent(
                                       qualifiedDomainObject.Stem!"",
                                       contentIfContent(
                                           qualifiedDomainObject.Name!"",
                                           ""
                                       )
                                   ),
                                   name
                               ) ]
            [/#if]
            [#if qualifiedDomainObject.Role?has_content]
                [#local role = qualifiedDomainObject.Role]
            [/#if]
        [/#list]
        [#local result +=
            [
                getCompositeObject( domainChildConfiguration, line + [{
                    "Name" : name,
                    "Role" : valueIfTrue(role, primaryNotSeen, DOMAIN_ROLE_SECONDARY)
                }] )
            ] ]
        [#local primaryNotSeen = primaryNotSeen && (role != DOMAIN_ROLE_PRIMARY) ]
    [/#list]

    [#-- Force first entry to primary if no primary seen --]
    [#if primaryNotSeen && (result?size > 0) ]
        [#local forcedResult = [ result[0] + { "Role" : DOMAIN_ROLE_PRIMARY } ] ]
        [#if (result?size > 1) ]
            [#local forcedResult += result[1..] ]
        [/#if]
        [#local result = forcedResult]
    [/#if]

    [#-- Add any domain inclusions --]
    [#local includes = certificateObject.IncludeInDomain!{} ]
    [#if includes?has_content]
        [#local hostParts = certificateObject.HostParts ]
        [#local parts = [] ]

        [#list hostParts as part]
            [#if includes[part]!false]
                [#switch part]
                    [#case "Segment"]
                        [#local parts += [segmentName!""] ]
                        [#break]
                    [#case "Environment"]
                        [#local parts += [environmentName!""] ]
                        [#break]
                    [#case "Product"]
                        [#local parts += [productName!""] ]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#local extendedResult = [] ]
        [#list result as entry]
            [#local extendedResult += [
                    entry +
                    {
                        "Name" : formatDomainName(parts, entry.Name)
                    }
                ] ]
        [/#list]
        [#local result = extendedResult]
    [/#if]

    [#return result]
[/#function]

[#function getCertificateObject start ]

    [#local certificateObject =
        getCompositeObject(
            certificateChildConfiguration,
            asFlattenedArray(
                arrayIfContent((blueprintObject.CertificateBehaviours)!{}, (blueprintObject.CertificateBehaviours)!{}) +
                arrayIfContent((tenantObject.CertificateBehaviours)!{}, (tenantObject.CertificateBehaviours)!{}) +
                arrayIfContent((productObject.CertificateBehaviours)!{}, (productObject.CertificateBehaviours)!{}) +
                ((getObjectLineage(certificates, [productId, productName])[0])![]) +
                ((getObjectLineage(certificates, start)[0])![])
            )
        )
    ]
    [#return
        certificateObject +
        {
            "Domains" : getDomainObjects(certificateObject)
        }
    ]
[/#function]

[#function getCertificateDomains certificateObject]
    [#return certificateObject.Domains![] ]
[/#function]

[#function getCertificatePrimaryDomain certificateObject]
    [#list certificateObject.Domains as domain]
        [#if isPrimaryDomain(domain) ]
            [#return domain ]
            [#break]
        [/#if]
    [/#list]
    [#return {} ]
[/#function]

[#function getCertificateSecondaryDomains certificateObject]
    [#local result = [] ]
    [#list certificateObject.Domains as domain]
        [#if isSecondaryDomain(domain) ]
            [#local result += [domain] ]
            [#break]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function getHostName certificateObject occurrence]

    [#local core = occurrence.Core ]
    [#local includes = certificateObject.IncludeInHost!{} ]
    [#local hostParts = certificateObject.HostParts ]
    [#local parts = [] ]

    [#list hostParts as part]
        [#if includes[part]!true]
            [#switch part]
                [#case "Host"]
                    [#local parts += [certificateObject.Host!""] ]
                    [#break]
                [#case "Tier"]
                    [#local parts += [getTierName(core.Tier)] ]
                    [#break]
                [#case "Component"]
                    [#local parts += [getComponentName(core.Component)] ]
                    [#break]
                [#case "Instance"]
                    [#local parts += [core.Instance.Name!""] ]
                    [#break]
                [#case "Version"]
                    [#local parts += [core.Version.Name!""] ]
                    [#break]
                [#case "Segment"]
                    [#local parts += [segmentName!""] ]
                    [#break]
                [#case "Environment"]
                    [#local parts += [environmentName!""] ]
                    [#break]
                [#case "Product"]
                    [#local parts += [productName!""] ]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]
    [#return
        valueIfTrue(
            certificateObject.Host!"",
            certificateObject.Host?has_content && (!(includes.Host!true)),
            formatName(parts)
        )
    ]
]
[/#function]

[#-- Build out a Name or File Path based on different layers or parts of the component id--]
[#function getContextPath occurrence pathObject={} ]

    [#local core = occurrence.Core ]
    [#local pathObject = pathObject?has_content?then(
                            pathObject,
                            occurrence.Configuration.Solution.Path)]
    [#local includes = pathObject.IncludeInPath ]

    [#local path = []]
    [#list (pathObject.Order)![] as part ]
        [#if (includes[part])!false ]
            [#switch part ]
                [#case "Account"]
                [#case "Product"]
                [#case "Solution"]
                [#case "Environment"]
                [#case "Segment"]
                    [#local layerDetails = getActiveLayer(part)]
                    [#if layerDetails?has_content ]
                        [#local path += [ (layerDetails.Name)!"" ]]
                    [/#if]
                    [#break]

                [#case "ProviderId" ]
                    [#local layerDetails = getActiveLayer("Account") ]
                    [#if layerDetails?has_content]
                        [#local path += [ (layerDetails.ProviderId)!"" ]]
                    [/#if]
                    [#break]

                [#case "Tier"]
                    [#local path += [ getTierName(core.Tier) ]]
                    [#break]

                [#case "Component"]
                    [#local path += [getComponentName(core.Component) ]]
                    [#break]

                [#case "Instance"]
                    [#local path += [((core.Instance.Name)!core.Instance.Id)!"" ]]
                    [#break]

                [#case "Version"]
                    [#local path += [((core.Version.Name)!core.Version.Id)!"" ]]
                    [#break]

                [#case "Custom"]
                    [#local path += [(pathObject.Custom)!""]]
                    [#break]
            [/#switch]
        [/#if]
    [/#list]

    [#switch pathObject.Style ]
        [#case "single" ]
            [#return formatName(path) ]
            [#break]

        [#default]
            [#return formatRelativePath(path)]
    [/#switch]
[/#function]

[#function getLBLink occurrence port ]

    [#assign core = occurrence.Core]
    [#assign targetTierId = (port.LB.Tier) ]
    [#assign targetComponentId = (port.LB.Component) ]
    [#assign targetLinkName = formatName(port.LB.LinkName) ]
    [#assign portMapping = contentIfContent(port.LB.PortMapping, port.Name)]

    [#-- Need to be careful to allow an empty value for --]
    [#-- Instance/Version to be explicitly provided and --]
    [#-- correctly handled in getLinkTarget.            --]
    [#--                                                --]
    [#-- Also note that the LinkName configuration      --]
    [#-- must be provided if more than one port is used --]
    [#-- (e.g. classic ELB) to avoid links overwriting  --]
    [#-- each other.                                    --]
    [#local targetLink =
        {
            "Id" : targetLinkName,
            "Name" : targetLinkName,
            "Tier" : targetTierId,
            "Component" : targetComponentId,
            "Enabled" : (port.LB.Enabled)!true
        } +
        attributeIfTrue("Instance", port.LB.Instance??, port.LB.Instance!"") +
        attributeIfTrue("Version",  port.LB.Version??, port.LB.Version!"") +
        attributeIfContent("SubComponent",  portMapping)
    ]
    [@debug message=targetLinkName context=targetLink enabled=false /]

    [#return { targetLinkName : targetLink } ]
[/#function]

[#function getRegistryLink occurrence port ]

    [#assign core = occurrence.Core]
    [#assign targetTierId = (port.Registry.Tier) ]
    [#assign targetComponentId = (port.Registry.Component) ]
    [#assign targetLinkName = formatName(port.Registry.LinkName) ]
    [#assign registryService = contentIfContent(port.Registry.RegistryService, port.Name)]

    [#-- Need to be careful to allow an empty value for --]
    [#-- Instance/Version to be explicitly provided and --]
    [#-- correctly handled in getLinkTarget.            --]
    [#--                                                --]
    [#-- Also note that the LinkName configuration      --]
    [#-- must be provided if more than one port is used --]
    [#-- to avoid links overwriting                     --]
    [#-- each other.                                    --]
    [#local targetLink =
        {
            "Id" : targetLinkName,
            "Name" : targetLinkName,
            "Tier" : targetTierId,
            "Component" : targetComponentId,
            "Enabled" : (port.Registry.Enabled)!true
        } +
        attributeIfTrue("Instance", port.Registry.Instance??, port.Registry.Instance!"") +
        attributeIfTrue("Version",  port.Registry.Version??, port.Registry.Version!"") +
        attributeIfContent("SubComponent",  registryService)
    ]
    [@debug message=targetLinkName context=targetLink enabled=false /]

    [#return { targetLinkName : targetLink } ]
[/#function]

[#function isDuplicateLink links link ]

    [#local linkKey = ""]
    [#list link as key,value]
        [#local linkKey = key]
        [#break]
    [/#list]

    [#return (links[linkKey])?? ]

[/#function]

[#function syncFilesToBucketScript filesArrayName region bucket prefix cleanup=true excludes=[] ]

    [#local excludeSwitches = ""]
    [#list asArray(excludes) as exclude]
        [#local excludeSwitches += " --exclude \"${exclude}\""]
    [/#list]

    [#return
        [
            "case $\{STACK_OPERATION} in",
            "  delete)",
            "    deleteTreeFromBucket" + " " +
                   "\"" + region + "\"" + " " +
                   "\"" + bucket + "\"" + " " +
                   "\"" + prefix + "\"" + " " +
                   "|| return $?",
            "    ;;",
            "  create|update)",
            "    debug \"FILES=$\{" + filesArrayName + "[@]}\"",
            "    #",
            "    syncFilesToBucket" + " " +
                   "\"" + region         + "\"" + " " +
                   "\"" + bucket         + "\"" + " " +
                   "\"" + prefix         + "\"" + " " +
                   "\"" + filesArrayName + "\"" + " " +
                   valueIfTrue("--delete", cleanup, "") +
                   excludeSwitches +
                   " || return $?",
            "    ;;",
            " esac",
            "#"
        ] ]
[/#function]

[#-- Writes a new file which will be synced to a bucket --]
[#function writeFileForSync filesArrayName fileName content ]
    [#return
        [
            r'echo "' + content + r'" > "${tmpdir}/' + fileName + r'"',
            r'addToArray "' + filesArrayName + r'" "${tmpdir}/' + fileName + r'"'
        ]
    ]
[/#function]

[#function findAsFilesScript filesArrayName settings]
    [#-- Create an array for the files --]
    [#local result = [] ]
    [#list settings as setting]
        [#if setting.AsFile?has_content]
            [#local result +=
                [
                    "addToArray" + " " +
                       "\"" + "filePathsToSync" + "\"" + " " +
                       "\"" + setting.AsFile    + "\""
                ] ]
        [/#if]
    [/#list]
    [#local result += ["#"] ]

    [#-- Locate where each file is --]
    [#return
        result +
        [
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{ROOT_DIR}" + "\"",
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{PRODUCT_APPSETTINGS_DIR}" + "\"",
            "addToArray" + " " +
               "\"" + "dirsToCheck"                 + "\"" + " " +
               "\"" + "$\{PRODUCT_CREDENTIALS_DIR}" + "\"",
            "#",
            "for f in \"$\{filePathsToSync[@]}\"; do",
            "  for d in \"$\{dirsToCheck[@]}\"; do",
            "    if [[ -f \"$\{d}/$\{f}\" ]]; then",
                   "addToArray" + " " +
                      filesArrayName + " " +
                      "\"$\{d}/$\{f}\"",
            "      break",
            "    fi",
            "  done",
            "done",
            "#"
        ] ]

[/#function]

[#function getBuildScript filesArrayName region registry product occurrence filename buildUnit=""]
    [#return
        [
            "copyFilesFromBucket" + " " +
              region + " " +
              getRegistryEndPoint(registry, occurrence) + " " +
              formatRelativePath(
                getRegistryPrefix(registry, occurrence),
                getOccurrenceBuildProduct(occurrence, product),
                getOccurrenceBuildScopeExtension(occurrence),
                buildUnit?has_content?then(
                    buildUnit,
                    getOccurrenceBuildUnit(occurrence)
                ),
                getOccurrenceBuildReference(occurrence)) + " " +
                "\"$\{tmpdir}\" || return $?",
            "#",
            "addToArray" + " " +
               filesArrayName + " " +
               "\"$\{tmpdir}/" + filename + "\"",
            "#"
        ] ]
[/#function]

[#function getLocalFileScript filesArrayName filepath filename=""]
    [#return
        valueIfContent(
            [
                "tmp_filename=\"" + filename + "\""
            ],
            filename,
            [
                "tmp_filename=\"$(fileName \"" + filepath + "\")\""
            ]
        ) +
        [
            r'if [[ -f "' + filepath + r'" ]]; then',
            "  cp" + " " +
               "\"" + filepath                      + "\"" + " " +
               "\"" + "$\{tmpdir}/$\{tmp_filename}" + "\"" + " || return $?",
            "  addToArray" + " " +
               filesArrayName + " " +
               "\"" + "$\{tmpdir}/$\{tmp_filename}" + "\"",
            r'fi'
        ] ]
[/#function]

[#function pseudoStackOutputScript description outputs filesuffix="" ]
    [#local outputString = ""]

    [#local baseOutputs = {} ]
    [#list getCFTemplateCoreOutputs(getRegion(), accountObject.ProviderId) as  key,value ]
        [#if value?is_hash ]
            [#local baseOutputs += { key, value.Value } ]
        [#else ]
            [#local baseOutputs += { key, value } ]
        [/#if]
    [/#list]

    [#-- Permit the base outputs to be overridden - mainly for the deployment unit --]
    [#list baseOutputs + outputs as key,value ]
        [#local outputString +=
          "\"" + key + "\" \"" + value + "\" "
        ]
    [/#list]

    [#return
        [
            "create_pseudo_stack" + " " +
            "\"" + description + "\"" + " " +
            "\"$\{CF_DIR}/$(fileBase \"$\{BASH_SOURCE}\")" + (filesuffix?has_content)?then("-" + filesuffix, "") + "-pseudo-stack.json\" " +
            outputString + " || return $?"
        ]
    ]

[/#function]

[#function getImageFromUrlScript region product environment segment occurrence sourceURL imageFormat registryFile expectedImageHash="" createZip=false  ]

    [#local registryBucket = getRegistryEndPoint(imageFormat, occurrence) ]
    [#local registryPrefix =
        formatRelativePath(
            getRegistryPrefix(imageFormat, occurrence),
            getOccurrenceBuildProduct(occurrence, product),
            getOccurrenceBuildScopeExtension(occurrence),
            occurrence.Core.Name
        )
    ]
    [#local buildUnit = occurrence.Core.Name ]

    [#return
        [
            r'if [[ "${HAMLET_SKIP_IMAGE_PULL}" != "true" ]]; then',
            r'   get_url_image_to_registry ' +
            r'     "' + sourceURL + r'" ' +
            r'     "' + expectedImageHash + r'" ' +
            r'     "' + imageFormat + r'" ' +
            r'     "' + region + r'" ' +
            r'     "' + registryBucket + r'" ' +
            r'     "' + registryPrefix + r'" ' +
            r'     "' + registryFile + r'" ' +
            r'     "' + product + r'" ' +
            r'     "' + environment + r'" ' +
            r'     "' + segment + r'" ' +
            r'     "' + buildUnit + r'" ' +
            r'     "' + createZip?c + r'" || exit $?',
            r'   # refresh settings to include new build file',
            r'',
            r'   assemble_settings "${GENERATION_DATA_DIR}" "${COMPOSITE_SETTINGS}"'
            r'else',
            r'   info "Skipping image pull as HAMLET_SKIP_IMAGE_PULL is set"',
            r'fi'
        ]
    ]
[/#function]

[#function getImageFromContainerRegistryScript
        product
        environment
        segment
        occurrence
        sourceImage
        imageFormat
        registryHost
        registryProvider
        region=""
    ]

    [#local buildUnit = getOccurrenceBuildUnit(occurrence) ]

    [#return
        [
            r'if [[ "${HAMLET_SKIP_IMAGE_PULL}" != "true" ]]; then',
            r'  get_image_from_container_registry' +
            r'   "' + sourceImage + r'" ' +
            r'   "' + imageFormat + r'" ' +
            r'   "' + product + r'" ' +
            r'   "' + environment + r'" ' +
            r'   "' + segment + r'" ' +
            r'   "' + buildUnit + r'" ' +
            r'   "' + registryHost + r'" ' +
            r'   "' + registryProvider + r'" ' +
            r'   "' + region + r'" || exit $? ',
            r'   # refresh settings to include new build file',
            r'',
            r'   assemble_settings "${GENERATION_DATA_DIR}" "${COMPOSITE_SETTINGS}"',
            r'else',
            r'   info "Skipping image pull as HAMLET_SKIP_IMAGE_PULL is set"',
            r'fi'
        ]
    ]
[/#function]

[#function getResourceFromId resources id ]
    [#list resources as key, value ]

        [#if key == id ]
            [#return value ]
        [/#if]

        [#if ! value?keys?seq_contains("Id") ]
            [#return getResourceFromId(value, id)]
        [/#if]
    [/#list]
    [#return {}]
[/#function]

[#function addIdNameToObject entity default=""]
    [#if entity?is_hash && default?has_content]
        [#return
            {
                "Id" : default,
                "Name" : default
            } + entity ]
    [/#if]
    [#return entity]
[/#function]

[#function addIdNameToObjectAttributes entity default=""]
    [#local result = entity]
    [#if entity?is_hash]
        [#list entity as key,value]
            [#local result += {key : addIdNameToObject(value, key)} ]
        [/#list]
    [/#if]
    [#return addIdNameToObject(result, default) ]
[/#function]
