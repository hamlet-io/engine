[#ftl]

[#----------------------------------------------
-- Public functions for occurrence processing --
------------------------------------------------]


[#-- Occurrence Caching controls - Provides a collection of occurrences to save the processing time in looking up the occurrence details --]
[#assign occurrenceCache = {}]

[#macro addOccurrenceToCache occurrence parentOccurrence={}  ]
    [#if parentOccurrence?has_content ]
        [@internalMergeOccurrenceCache
            tierId=parentOccurrence.Core.Tier.Id
            componentId=parentOccurrence.Core.Component.RawId
            instanceId=parentOccurrence.Core.Instance.Id
            versionId=parentOccurrence.Core.Version.Id
            subComponentId=occurrence.Core.SubComponent.RawId
            subInstanceId=occurrence.Core.Instance.Id
            subVersionId=occurrence.Core.Version.Id
            occurrence=occurrence
        /]
    [#else]
        [@internalMergeOccurrenceCache
            tierId=occurrence.Core.Tier.Id
            componentId=occurrence.Core.Component.RawId
            instanceId=occurrence.Core.Instance.Id
            versionId=occurrence.Core.Version.Id
            occurrence=occurrence
        /]
    [/#if]
[/#macro]


[#function getOccurrenceDetailsFromCache occurrence parentOccurrence={} ]
    [#local occurrenceDetails = {}]
    [#if parentOccurrence?has_content  ]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local componentId = parentOccurrence.Core.Component.RawId ]
        [#local instanceId = parentOccurrence.Core.Instance.Id ]
        [#local versionId = parentOccurrence.Core.Version.Id ]
        [#local subComponentId = occurrence.Core.SubComponent.RawId ]
        [#local subComponentType = occurrence.Core.Type ]
        [#local subInstanceId = occurrence.Core.Instance.Id ]
        [#local subVersionId = occurrence.Core.Version.Id ]

        [#local occurrenceDetails =
            (occurrenceCache[tierId][componentId][instanceId][versionId]["SubComponents"][subComponentId][subComponentType][subInstanceId][subVersionId])!{} ]
    [#else]
        [#local tierId = occurrence.Core.Tier.Id ]
        [#local componentId = occurrence.Core.Component.RawId ]
        [#local instanceId = occurrence.Core.Instance.Id ]
        [#local versionId = occurrence.Core.Version.Id ]

        [#local occurrenceDetails =
            (occurrenceCache[tierId][componentId][instanceId][versionId]["Component"])!{} ]
    [/#if]

    [#if occurrenceDetails?has_content ]
        [#return occurrenceDetails ]
    [/#if]
    [#return { "Present" : false, "Occurrence" : {} } ]
[/#function]

[#function getOccurrenceFromCache occurrence parentOccurrence={} ]
    [#local occurrenceCacheItem = getOccurrenceDetailsFromCache(occurrence, parentOccurrence)]
    [#return occurrenceCacheItem.Occurrence ]
[/#function]

[#function isOccurrenceCached occurrence parentOccurrence={} ]
    [#local occurrenceCacheItem = getOccurrenceDetailsFromCache(occurrence, parentOccurrence )]
    [#return occurrenceCacheItem.Present ]
[/#function]

[#function getOccurrenceSettingValue occurrence names emptyIfNotProvided=false]
    [#return internalGetOccurrenceSetting(occurrence, names, emptyIfNotProvided).Value]
[/#function]

[#function getOccurrenceBuildReference occurrence emptyIfNotProvided=false]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_REFERENCE", true),
            valueIfTrue(
                "",
                emptyIfNotProvided,
                "HamletFatal: Build reference not found"
            )
        ) ]
[/#function]

[#function getOccurrenceBuildUnit occurrence emptyIfNotProvided=false]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(occurrence, "BUILD_UNIT", true),
            valueIfTrue(
                "",
                emptyIfNotProvided,
                "HamletFatal: Build unit not found"
            )
        ) ]
[/#function]

[#function getOccurrenceBuildScopeExtension occurrence ]
    [#local extension = ""]
    [#local scope = getOccurrenceSettingValue(occurrence, "BUILD_SCOPE", true)?trim ]
    [#switch scope]
        [#case "account"]
            [#break]
        [#case "segment"]
            [#local extension = segmentName]
            [#break]
        [#default]
            [#local extension = scope]
            [#break]
    [/#switch]

    [#return extension]
[/#function]

[#function getOccurrenceBuildProduct occurrence product]
    [#local result = product]
    [#local scope = getOccurrenceSettingValue(occurrence, "BUILD_SCOPE", true)?trim ]
    [#switch scope]
        [#case "account"]
            [#local result = accountName]
            [#break]
    [/#switch]

    [#return result]
[/#function]

[#function getOccurrenceNetwork occurrence]
    [#return getTierNetwork(occurrence.Core.Tier.Id)]
[/#function]

[#function getOccurrenceDeploymentUnit occurrence]
    [#local solution = (occurrence.Configuration.Solution)!{} ]
    [#return getDeploymentUnitId(solution) ]
[/#function]

[#function getOccurrenceDeploymentGroup occurrence]
    [#local solution = (occurrence.Configuration.Solution)!{} ]
    [#return solution["deployment:Group"]!"" ]
[/#function]

[#function isOccurrenceEnabled occurrence]
    [#return (occurrence.Configuration.Solution.Enabled)!true ]
[/#function]

[#function isOccurrenceExternal occurrence]
    [#return (occurrence.Core.External)!false ]
[/#function]

[#function isOccurrenceDeployed occurrence]
    [#return
        isOccurrenceEnabled(occurrence) &&
        internalIsOneResourceDeployed((occurrence.State.Resources)!{}) ]
[/#function]

[#function getOccurrenceCore occurrence ]
    [#return (occurrence.Core)!{} ]
[/#function]

[#function getOccurrenceType occurrence ]
    [#return occurrence.Core.Type]
[/#function]

[#function getOccurrenceTier occurrence ]
    [#return occurrence.Core.Tier]
[/#function]

[#function getOccurrenceComponent occurrence ]
    [#return occurrence.Core.Component]
[/#function]

[#function getOccurrenceSubComponent occurrence ]
    [#return occurrence.Core.SubComponent!{} ]
[/#function]

[#function getOccurrenceInstance occurrence ]
    [#return occurrence.Core.Instance]
[/#function]

[#function getOccurrenceVersion occurrence ]
    [#return occurrence.Core.Version]
[/#function]

[#function getOccurrenceRole occurrence direction role]
    [#return (occurrence.State.Roles[direction?capitalize][role])!{} ]
[/#function]

[#function getOccurrenceDefaultRole occurrence direction]
    [#return (occurrence.State.Roles[direction?capitalize]["default"])!"" ]
[/#function]

[#function getOccurrenceSolution occurrence ]
    [#return (occurrence.Configuration.Solution)!{} ]
[/#function]

[#function getOccurrenceLocations occurrence ]
    [#return (occurrence.Configuration.Locations)!{} ]
[/#function]

[#function getOccurrenceResources occurrence ]
    [#return (occurrence.State.Resources)!{} ]
[/#function]

[#function getOccurrenceAttributes occurrence ]
    [#return (occurrence.State.Attributes)!{} ]
[/#function]

[#function getOccurrenceChildren occurrence]
    [#return (occurrence.Occurrences)![] ]
[/#function]

[#function hasOccurrenceChildren occurrence]
    [#return getOccurrenceChildren(occurrence)?has_content ]
[/#function]

[#function occurrencesInSameDeployment occurrenceA occurrenceB]
    [#return
        getOccurrenceDeploymentUnit(occurrenceA) == getOccurrenceDeploymentUnit(occurrenceB) &&
        ( getOccurrenceDeploymentGroup(occurrenceA) == getOccurrenceDeploymentGroup(occurrenceB) ||
            (
                getOccurrenceDeploymentGroup(occurrenceB) == "" &&
                occurrenceA.Core.Component.RawId == occurrenceB.Core.Component.RawId
            )
        )]
[/#function]

[#-- Summary occurrence information to provide useful information --]
[#-- when debugging errors without swamping the output            --]
[#function getOccurrenceSummary occurrences]
    [#local result = [] ]
    [#list asArray(occurrences) as occurrence]
        [#local result +=
            [
                {
                    "Type" : occurrence.Core.Type,
                    "Core" : {
                        "Tier" : occurrence.Core.Tier.Id,
                        "Component" : occurrence.Core.Component.Id,
                        "Instance" : occurrence.Core.Instance.Id,
                        "Version" : occurrence.Core.Version.Id
                    } +
                    attributeIfContent("SubComponent", (occurrence.SubComponent.Id)!"")
                }
            ]
        ]
    [/#list]
    [#if result?size > 1]
        [#return result]
    [/#if]
    [#return result[0]!{} ]
[/#function]

[#function constructOccurrenceSettings baseOccurrence type]

    [#local occurrence = baseOccurrence]

    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Core" : {
                    "Id" : formatId(occurrence.Core.Extensions.Id),
                    "RawId" : formatId(occurrence.Core.Extensions.RawId),
                    "TypedId" : formatId(occurrence.Core.Extensions.Id, type),
                    "Name" : formatName(occurrence.Core.Extensions.Name),
                    "RawName" : formatName(occurrence.Core.Extensions.RawName),
                    "TypedName" : formatName(occurrence.Core.Extensions.Name, type),
                    "TypedRawName" : formatName(occurrence.Core.Extensions.RawName, type),
                    "FullName" : formatSegmentFullName(occurrence.Core.Extensions.Name),
                    "RawFullName" : formatSegmentFullName(occurrence.Core.Extensions.RawName),
                    "TypedFullName" : formatSegmentFullName(occurrence.Core.Extensions.Name, type),
                    "ShortName" : formatName(occurrence.Core.Extensions.Id),
                    "ShortRawName" : formatName(occurrence.Core.Extensions.RawName),
                    "ShortTypedName" : formatName(occurrence.Core.Extensions.Id, type),
                    "ShortTypedRawName" : formatName(occurrence.Core.Extensions.RawId, type),
                    "ShortFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id),
                    "ShortRawFullName" : formatSegmentShortName(occurrence.Core.Extensions.RawId),
                    "ShortTypedFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id, type),
                    "ShortTypedRawFullName" : formatSegmentShortName(occurrence.Core.Extensions.Raw, type),
                    "RelativePath" : formatRelativePath(occurrence.Core.Extensions.Name),
                    "ReltiveRawPath" : formatRelativePath(occurrence.Core.Extensions.RawName),
                    "FullRelativePath" : formatSegmentRelativePath(occurrence.Core.Extensions.Name),
                    "FullRealitveRawPath" : formatSegmentRelativePath(occurrence.Core.Extensions.RawName),
                    "AbsolutePath" : formatAbsolutePath(occurrence.Core.Extensions.Name),
                    "AbsoluteRawPath" : formatAbsolutePath(occurrence.Core.Extensions.RawName),
                    "FullAbsolutePath" : formatSegmentAbsolutePath(occurrence.Core.Extensions.Name),
                    "FullAbsoluteRawPath" : formatSegmentAbsolutePath(occurrence.Core.Extensions.RawName)
                }
            }
        ) ]

    [#-- define the setting namespaces for the component --]
    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Configuration" : {
                    "SettingNamespaces" : internalGetOccurrenceSettingNamespaces(occurrence)
                }
            }
        )
    ]

    [#-- use the namespaces to determine settings --]
    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Configuration" : {
                    "Settings" : {
                        "Build" : internalCreateOccurrenceBuildSettings(occurrence),
                        "Account" : internalCreateAccountSettings(),
                        "Product" :
                            internalCreateOccurrenceProductSettings(occurrence) +
                            internalCreateOccurrenceSensitiveSettings(occurrence),
                        "Component" : internalCreateOccurrenceComponentSettings(occurrence)
                    }
                }
            }
        ) ]

    [#-- Some core settings are controlled by product level settings --]
    [#-- (e.g. file prefixes) so initialise core last                --]
    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Configuration" : {
                    "Settings" : {
                        "Core" : internalCreateOccurrenceCoreSettings(occurrence)
                    }
                }
            }
        ) ]
    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Configuration" : {
                    "Environment" : {
                        "Build" :
                            getSettingsAsEnvironment(occurrence.Configuration.Settings.Build),
                        "General" :
                            internalGetOccurrenceSettingsAsEnvironment(
                                occurrence,
                                {"Include" : {"Sensitive" : false}}
                            ),
                        "Sensitive" :
                            internalGetOccurrenceSettingsAsEnvironment(
                                occurrence,
                                {"Include" : {"General" : false}}
                            )
                    }
                }
            }
        ) ]
    [#return occurrence]
[/#function]

[#--
Attribute extension

Attribute extension is designed to permit providers to supplement any attributes
defined in the shared provider. It is done in a way that permits multiple
providers to extend the attributes simultaneously, but with extensions specific
to the provider easily identified.

A provider has two options - enrich an existing attribute or add namespaced attributes.

** Attribute enrichment **

If the name of the extension matches one of the names of the existing attributes,
the attribute maintains its existing name, and the extension configuration is
merged with the existing attribute configuration.

Where the existing attribute has children, the extension is also expected to have
children and attribute extension is recursively applied to each child.

Where the extension provides possible values, any unique values are added to
the existing attribute values. By default these values are prefixed based on the
provided prefix attribute (a colon is used as a separator). However if the
extension value starts with the provided disablePrefix, the disablePrefix is stripped.
This allows a provider to contribute sharable as well as provider specific values.

If the extension provides a default value, it will be merged with any existing
value.

If the extension provides an attribute set, this overrides any children definition
currently on the existing attribute.

** Namespaced attribute addition **

If the extension names do not overlap those of the existing attributes, the extension
is added to the list of attributes. All the extension names has the provided prefix
added. Any Values or Default value are NOT prefixed, as they are defined within an
already prefixed attribute.

--]
[#function extendAttributes attributes=[] extensions=[] prefix="" disablePrefix="shared:" ]

    [#if ! extensions?has_content]
        [#-- Nothing to do --]
        [#return attributes]
    [/#if]

    [#local result = [] ]
    [#local prefix = prefix?ensure_ends_with(":") ]

    [#-- First extend existing attributes --]
    [#list asArray(attributes) as attribute]

        [#-- Check if any of the extensions have a name matching one of the existing attribute names --]
        [#local attributeExtensions =
            asArray(extensions)?filter(
                e ->
                    getArrayIntersection(
                        asArray(attribute.Names),
                        asArray(e.Names)
                    )?has_content
            )
        ]

        [#-- At most one extension should match the existing attribute --]
        [#if attributeExtensions?size > 1]
            [@warning
                message="Multiple attribute extensions match attribute"
                context={
                    "Attribute" : attribute,
                    "MatchingExtensions" : attributeExtensions
                }
            /]
        [/#if]

        [#if attributeExtensions?has_content]
            [#local attributeExtension = attributeExtensions?first]
            [#if (attribute.Children![])?has_content]
                [#-- Recursively extend child definitions --]
                [#if (attributeExtension.Children![])?has_content]
                    [#local result += [
                        mergeObjects(
                            attribute,
                            {
                                "Children" : extendAttributes(
                                                attribute.Children,
                                                attributeExtension.Children,
                                                prefix)
                            }
                        )
                    ]]
                [#else]
                    [@fatal
                        message="Attribute Extension missing children."
                        context={
                            "Attribute" : attribute,
                            "Extension" : attributeExtension
                        }
                    /]
                [/#if]
            [#else]

                [#local extendedAttributes = {}]
                [#local extendedValues = (attribute.Values)![]]

                [#-- Check for extra values --]
                [#list (attributeExtension.Values)![] as extensionValue]

                    [#if extensionValue?is_string ]
                        [#-- If extension value starts with the disable prefix, --]
                        [#-- value is shared so strip prefix, otherwise         --]
                        [#-- force extension value to be prefixed               --]
                        [#local extendedValues +=
                            [
                                extensionValue?starts_with(disablePrefix)?then(
                                    extensionValue?remove_beginning(disablePrefix),
                                    extensionValue?ensure_starts_with(prefix)
                                )
                            ]]
                    [#else ]
                        [#local extendedValues += extensionValue ]
                    [/#if]

                    [#-- At least one extended value so update the values list --]
                    [#local extendedAttributes += {
                        "Values" : getUniqueArrayElements(extendedValues)
                    }]

                [/#list]

                [#-- Check for different default --]
                [#if ((attributeExtension.Default)!"")?has_content ]
                    [#local extendedAttributes += {
                        "Default" : attributeExtension.Default
                    } ]
                [/#if]

                [#-- Extension has extra attributes defined via an attribute set --]
                [#if ((attributeExtension.AttributeSet)![])?has_content ]
                    [#local extendedAttributes += {
                        "AttributeSet" : attributeExtension.AttributeSet,
                        "Children" : []
                    }]
                [/#if]

                [#local result += [
                    mergeObjects(
                        attribute,
                        extendedAttributes
                    )]]
            [/#if]
        [#else]
            [#local result += [attribute]]
        [/#if]
    [/#list]

    [#-- Deal with any new attributes contributed by the extensions --]
    [#local additionalAttributes = [] ]
    [#list extensions as extension ]

        [#-- Check if the extension has a name matching one of the existing attribute names --]
        [#-- If it does, it will already have been processed                                --]
        [#if !
            asArray(attributes)?filter(
                a ->
                    getArrayIntersection(
                        asArray(extension.Names),
                        asArray(a.Names)
                    )?has_content
            )?has_content
        ]
            [#-- The provided extension names will be prefixed. Any values or default are --]
            [#-- NOT prefixed given that the extension names are prefixed.                --]
            [#local additionalAttributes +=
                addPrefixToAttributes(
                    [ extension ],
                    prefix,
                    true,
                    false,
                    false
                )
            ]
        [/#if]
    [/#list]
    [#local result += additionalAttributes ]

    [#return result]
[/#function]

[#function constructOccurrenceAttributes occurrence]
    [#local attributes = [] ]

    [#list getComponentResourceGroups(occurrence.Core.Type) as key, value]
        [#local placement = (occurrence.State.ResourceGroups[key].Placement)!{}]
        [#local provider = placement.Provider!"" ]

        [#local attributes += getComponentResourceGroupAttributes(value, provider)]

    [/#list]
    [#return attributes]
[/#function]

[#function constructOccurrenceState occurrence parentOccurrence]

    [#local groupState = {} ]
    [#local attributes = {} ]

    [#-- TODO(mfl) Remove legacyState once all components using access routines --]
    [#local legacyState = {
            "Resources" : {},
            "Roles" : {
                "Inbound" : {},
                "Outbound" : {}
            }
        } ]

    [#-- Special processing for external links --]
    [#if (occurrence.Core.External!false) || ((occurrence.Core.Type!"") == "external") ]
        [#local environment =
            occurrence.Configuration.Environment.General +
            occurrence.Configuration.Environment.Sensitive ]

        [#list environment as name,value]
            [#local prefix = occurrence.Core.Component.Name?upper_case + "_"]
            [#if name?starts_with(prefix)]
                [#local attributes += { name?remove_beginning(prefix) : value } ]
            [/#if]
        [/#list]
    [/#if]

    [#-- Get the state of each resource group --]
    [#list occurrence.State.ResourceGroups as key, value]

        [#-- Default resource group state --]
        [#local state =
            {
                "Resources" : {},
                "Roles" : {
                    "Inbound" : {},
                    "Outbound" : {}
                },
                "Attributes" : {}
            }
        ]

        [#-- Attempt to invoke state macro for resource group --]
        [#if invokeStateMacro(occurrence, key, parentOccurrence)]
            [#local state = mergeObjects(state, componentState) ]
        [#else]
            [@debug
                message="State macro for resource group " + key + " not found"
                enabled=false
            /]
        [/#if]

        [#-- Update resource deployment status --]
        [#local state +=
            {
                "Resources" : internalGetDeploymentState(state.Resources)
            } ]

        [#-- Accumulate resource group state --]
        [#local groupState += { key : state } ]

        [#-- Accumulate attributes --]
        [#local attributes += state.Attributes!{}]

        [#-- Accumulate legacy state --]
        [#local legacyState = mergeObjects(legacyState, state) ]
    [/#list]

    [#-- Incorporate into existing state --]
    [#return
        mergeObjects(
            occurrence.State!{},
            {
                "ResourceGroups" : groupState,
                "Attributes" : attributes
            } +
            removeObjectAttributes(legacyState, "Attributes")
        ) ]
[/#function]

[#function getSettingNamespaces occurrence namespaceObjects ]

    [#local core = occurrence.Core ]
    [#local namespaces = []]

    [#list namespaceObjects as id,namespaceObject ]
        [#local includes = namespaceObject.IncludeInNamespace!{} ]
        [#local parts = []]
        [#local order = namespaceObject.Order ]

        [#list order as part]
            [#if includes[part]!true]
                [#switch part]
                    [#case "Tier"]
                        [#local parts += [core.Tier.Name!""] ]
                        [#break]
                    [#case "Component"]
                        [#local parts += [ core.Component.Name!"" ] ]
                        [#break]
                    [#case "SubComponent"]
                        [#local parts += [ core.SubComponent.Name!""] ]
                        [#break]
                    [#case "Instance"]
                        [#local parts += [core.Instance.Name!""] ]
                        [#break]
                    [#case "Version"]
                        [#local parts += [core.Version.Name!""] ]
                        [#break]
                    [#case "Name"]
                        [#local parts += [namespaceObject.Name!""] ]
                        [#break]
                [/#switch]
            [/#if]
        [/#list]

        [#local namespaces +=
            [
                {
                    "Key" : formatName(parts)?lower_case,
                    "Match" : namespaceObject.Match
                }
            ]
        ]
    [/#list]
    [#return namespaces]
[/#function]

[#function getAdditionalBuildSettings namespaces ]
    [#return internalCreateOccurrenceBuildSettings(
        {
            "Configuration" : {
                "SettingNamespaces" : asFlattenedArray(namespaces)
            }
        }
    )]
[/#function]

[#--------------------------------------------------------
-- Internal support functions for occurrence processing --
----------------------------------------------------------]

[#function internalGetDeploymentState resources ]
    [#local result = resources ]
    [#if resources?is_hash]
        [#list resources as alias,resource]
            [#if resource.Id?has_content]
                [#local result +=
                    {
                        alias :
                          resource +
                          {
                              "Deployed" : resource.Deployed!(getExistingReference(resource.Id)?has_content)
                          }
                    } ]
            [#else]
                [#local result +=
                    {
                        alias : internalGetDeploymentState(resource)
                    } ]
            [/#if]
        [/#list]
    [/#if]
    [#return result]
[/#function]

[#function internalGetOccurrenceSettingNamespaces occurrence ]
    [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]
    [#local solutionNamespaces = (occurrence.Configuration.Solution.SettingNamespaces)!{}]

    [#local namespaces =
        solutionNamespaces?has_content?then(
            getSettingNamespaces(occurrence, solutionNamespaces),
            []
        ) +
        [
            {"Key" : (occurrence.Core.Name)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.RawName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.TypedName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.TypedRawName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.ShortName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.ShortRawName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.ShortTypedName)?lower_case, "Match" : "partial"},
            {"Key" : (occurrence.Core.ShortTypedRawName)?lower_case, "Match" : "partial"}
        ] +
        valueIfContent(
            [ {"Key": deploymentUnit?lower_case, "Match" : "exact"} ]
            deploymentUnit,
            []
        )
    ]
    [#return namespaces ]
[/#function]

[#function internalCreateOccurrenceSettings possibilities root prefixes alternatives]

    [#-- Add the root to each prefix --]
    [#local namespacePrefixes = [] ]
    [#list prefixes as prefix]
        [#local namespacePrefixes += [formatName(root, prefix)] ]
    [/#list]

    [#-- Get the keys of the matching possibilities --]
    [#local matches = getMatchingNamespaces(possibilities?keys, namespacePrefixes, alternatives, ["-asfile"]) ]

    [#-- Get the values of matching possibilities --]
    [#local contexts = [] ]
    [#list matches as match]
        [#if possibilities[match]?has_content]
            [#local contexts += [possibilities[match]] ]
        [/#if]
    [/#list]

    [#return asFlattenedSettings(getCompositeObject([{ "Names" : "*" }], contexts)) ]
[/#function]

[#function internalGetOccurrenceSetting occurrence names emptyIfNotProvided=false]
    [#return getFirstSetting(
        [
            (occurrence.Configuration.Settings.Account)!{},
            (occurrence.Configuration.Settings.Product)!{},
            (occurrence.Configuration.Settings.Component)!{},
            (occurrence.Configuration.Settings.Core)!{},
            (occurrence.Configuration.Settings.Build)!{}
        ],
        names,
        emptyIfNotProvided)
    ]
[/#function]

[#function internalCreateOccurrenceCoreSettings occurrence]
    [#local core = occurrence.Core ]
    [#return
        asFlattenedSettings(
            {
                "TEMPLATE_TIMESTAMP" : .now?iso_utc,
                "PRODUCT" : productName,
                "ENVIRONMENT" : environmentName,
                "SEGMENT" : segmentName,
                "TIER" : core.Tier.Name,
                "COMPONENT" : core.Component.Name,
                "COMPONENT_INSTANCE" : core.Instance.Name,
                "COMPONENT_VERSION" : core.Version.Name,
                "REQUEST_REFERENCE" : getCLORequestReference(),
                "CONFIGURATION_REFERENCE" : getCLOConfigurationReference(),
                "APPDATA_PREFIX" : getAppDataFilePrefix(occurrence),
                "APPSETTINGS_PREFIX" : getSettingsFilePrefix(occurrence),
                "CREDENTIALS_PREFIX" : getSettingsFilePrefix(occurrence),
                "SETTINGS_PREFIX" : getSettingsFilePrefix(occurrence)
            } +
            attributeIfContent("SUBCOMPONENT", (core.SubComponent.Name)!"") +
            attributeIfContent("APPDATA_PUBLIC_PREFIX", getAppDataPublicFilePrefix(occurrence)) +
            attributeIfContent("SES_REGION", (productObject.SES.Region)!"")
        )
    ]
[/#function]

[#function internalCreateAccountSettings ]
    [#local alternatives = [{"Key" : "shared", "Match" : "exact"}] ]

    [#-- Fudge prefixes for accounts --]
    [#return
        internalCreateOccurrenceSettings(
            (getSettings().Settings.Accounts)!{},
            accountName,
            [""],
            alternatives) ]
[/#function]

[#function internalCreateOccurrenceBuildSettings occurrence ]
    [#local namespaces = occurrence.Configuration.SettingNamespaces ]
    [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]

    [#local occurrenceBuild =
        internalCreateOccurrenceSettings(
            (getSettings().Builds.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            namespaces
        ) ]

    [#-- a local unit build commit/tag takes preference over a shared one --]
    [#local occurrenceBuildCommit = occurrenceBuild.COMMIT!{} ]
    [#local occurrenceBuildTag = occurrenceBuild.TAG!{} ]
    [#local occurrenceBuildFormats = occurrenceBuild.FORMATS!{} ]
    [#local occurrenceBuildScope = occurrenceBuild.SCOPE!{} ]

    [#-- Reference could be to a deployment unit (legacy) or a component --]
    [#local matchedReference = "" ]
    [#if occurrenceBuild.REFERENCE?has_content]
        [#-- Support cross-segment references --]
        [#if occurrenceBuild.SEGMENT?has_content]
            [#local buildLookupPrefixes =
                [
                    ["shared", occurrenceBuild.SEGMENT.Value],
                    [environmentName, occurrenceBuild.SEGMENT.Value]
                ] +
                cmdbProductLookupPrefixes ]
        [#else]
            [#local buildLookupPrefixes = cmdbProductLookupPrefixes]
        [/#if]
        [#-- Support provision of multiple references to permit --]
        [#-- a transition from deployment unit based references --]
        [#-- to occurrence based references                     --]
        [#-- Occurrence value should go last to take priority   --]
        [#-- to permit gradual conversion of references         --]
        [#list asArray(occurrenceBuild.REFERENCE.Value) as reference]
            [#local formattedReference = reference?replace("/","-")]
            [#local nextReference =
                internalCreateOccurrenceSettings(
                    (getSettings().Builds.Products)!{},
                    productName,
                    buildLookupPrefixes,
                    [
                        {"Key" : formattedReference, "Match" : "exact"}
                    ]
                ) ]
            [#if nextReference?has_content]
                [#local matchedReference = formattedReference ]
                [#local occurrenceBuild += nextReference ]
            [/#if]
       [/#list]
    [/#if]

    [#return
        attributeIfContent(
            "BUILD_FORMATS",
            contentIfContent(occurrenceBuildFormats, occurrenceBuild.FORMATS!{})
        ) +
        attributeIfContent(
            "BUILD_REFERENCE",
            contentIfContent(occurrenceBuildCommit, occurrenceBuild.COMMIT!{})
        ) +
        attributeIfTrue(
            "BUILD_SCOPE",
            occurrenceBuildScope?has_content || occurrenceBuild.SCOPE?has_content,
            {
                "Internal" : true
            } +
            contentIfContent(occurrenceBuildScope, occurrenceBuild.SCOPE!{})
        ) +
        attributeIfContent(
            "APP_REFERENCE",
            contentIfContent(occurrenceBuildTag, occurrenceBuild.TAG!{})
        ) +
        attributeIfContent(
            "BUILD_UNIT",
            occurrenceBuild.UNIT!
            valueIfContent(
                {"Value" : matchedReference},
                matchedReference,
                valueIfContent(
                    {"Value" : deploymentUnit},
                    deploymentUnit
                )
            )
        )
    ]
[/#function]

[#function internalCreateOccurrenceComponentSettings occurrence]
    [#local result = {}]
    [#list (occurrence.Configuration.Solution.Settings)!{} as id, setting]
        [#if (setting.Enabled)!true]
            [#local result = mergeObjects(
                result,
                {
                    id : {
                        "Value" : setting.Value,
                        "Sensitive" : setting.Sensitive,
                        "Internal" : setting.Internal
                    }
                }
            )]
        [/#if]
    [/#list]
    [#return result ]
[/#function]

[#function internalCreateOccurrenceProductSettings occurrence ]
    [#local namespaces = occurrence.Configuration.SettingNamespaces ]
    [#return
        internalCreateOccurrenceSettings(
            (getSettings().Settings.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            namespaces) ]
[/#function]

[#function internalCreateOccurrenceSensitiveSettings occurrence]
    [#local namespaces = occurrence.Configuration.SettingNamespaces ]

    [#return
        markAsSensitiveSettings(
            internalCreateOccurrenceSettings(
                (getSettings().Sensitive.Products)!{},
                productName,
                cmdbProductLookupPrefixes,
                namespaces) ) ]
[/#function]

[#function internalGetOccurrenceSettingsAsEnvironment occurrence format]
    [#return
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Core, format) +
        getSettingsAsEnvironment(occurrence.Configuration.Settings.Product, format) ]
[/#function]

[#function internalIsOneResourceDeployed resources ]
    [#if resources?is_hash]
        [#if resources?has_content ]
            [#list resources as alias,resource]
                [#if resource.Id?has_content]
                    [#if resource.Deployed && resource.IncludeInDeploymentState!true]
                        [#return true]
                    [/#if]
                [#else]
                    [#if internalIsOneResourceDeployed(resource) ]
                        [#return true]
                    [/#if]
                [/#if]
            [/#list]
        [#else]
            [#return true]
        [/#if]
    [/#if]
    [#return false]
[/#function]

[#macro internalMergeOccurrenceCache occurrence tierId componentId instanceId versionId subComponentId="" subInstanceId="" subVersionId="" ]
    [#if subComponentId?has_content ]
        [#assign occurrenceCache =
            mergeObjects(
                occurrenceCache,
                {
                    tierId : {
                        componentId : {
                            instanceId : {
                                versionId : {
                                    "SubComponents" : {
                                        subComponentId : {
                                            subInstanceId : {
                                                subVersionId : {
                                                    "Present" : true,
                                                    "Occurrence" : occurrence
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )]
    [#else]
        [#assign occurrenceCache =
            mergeObjects(
                occurrenceCache,
                {
                    tierId : {
                        componentId : {
                            instanceId : {
                                versionId : {
                                    "Component" : {
                                        "Present" : true,
                                        "Occurrence" : occurrence
                                    }
                                }
                            }
                        }
                    }
                }
            )]
    [/#if]
[/#macro]
