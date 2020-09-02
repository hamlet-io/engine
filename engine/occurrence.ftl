[#ftl]

[#----------------------------------------------
-- Public functions for occurrence processing --
------------------------------------------------]

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
                "COTFatal: Build reference not found"
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
                "COTFatal: Build unit not found"
            )
        ) ]
[/#function]

[#function getOccurrenceBuildScopeExtension occurrence ]
    [#local extension = ""]
    [#switch getOccurrenceSettingValue(occurrence, "BUILD_SCOPE", true)]
        [#case "segment"]
            [#local extension = segmentName]
            [#break]
    [/#switch]

    [#return extension]
[/#function]

[#function getOccurrenceNetwork occurrence]
    [#return getTierNetwork(occurrence.Core.Tier.Id)]
[/#function]

[#function getOccurrenceFragmentBase occurrence]
    [#return contentIfContent((occurrence.Configuration.Solution.Fragment)!"", occurrence.Core.Component.Id)]
[/#function]

[#function getOccurrenceDeploymentUnit occurrence]
    [#local solution = occurrence.Configuration.Solution ]
    [#return getDeploymentUnitId(solution) ]
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

[#function getOccurrenceResources occurrence ]
    [#return (occurrence.State.Resources)!{} ]
[/#function]

[#function getOccurrenceChildren occurrence]
    [#return (occurrence.Occurrences)![] ]
[/#function]

[#function hasOccurrenceChildren occurrence]
    [#return getOccurrenceChildren(occurrence)?has_content ]
[/#function]

[#function constructOccurrenceSettings baseOccurrence type]

    [#local occurrence = baseOccurrence]

    [#local occurrence =
        mergeObjects(
            occurrence,
            {
                "Core" : {
                    "Id" : formatId(occurrence.Core.Extensions.Id),
                    "TypedId" : formatId(occurrence.Core.Extensions.Id, type),
                    "Name" : formatName(occurrence.Core.Extensions.Name),
                    "TypedName" : formatName(occurrence.Core.Extensions.Name, type),
                    "FullName" : formatSegmentFullName(occurrence.Core.Extensions.Name),
                    "TypedFullName" : formatSegmentFullName(occurrence.Core.Extensions.Name, type),
                    "ShortName" : formatName(occurrence.Core.Extensions.Id),
                    "ShortTypedName" : formatName(occurrence.Core.Extensions.Id, type),
                    "ShortFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id),
                    "ShortTypedFullName" : formatSegmentShortName(occurrence.Core.Extensions.Id, type),
                    "RelativePath" : formatRelativePath(occurrence.Core.Extensions.Name),
                    "FullRelativePath" : formatSegmentRelativePath(occurrence.Core.Extensions.Name),
                    "AbsolutePath" : formatAbsolutePath(occurrence.Core.Extensions.Name),
                    "FullAbsolutePath" : formatSegmentAbsolutePath(occurrence.Core.Extensions.Name)
                }
            }
        ) ]

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
                            internalCreateOccurrenceSensitiveSettings(occurrence)
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

[#function constructOccurrenceAttributes occurrence]
    [#local attributes = [] ]

    [#list getComponentResourceGroups(occurrence.Core.Type) as key, value]
        [#local placement = (occurrence.State.ResourceGroups[key].Placement)!{}]
        [#local attributes +=
            (value.Attributes[SHARED_ATTRIBUTES]![]) +
            (value.Attributes[DEPLOYMENT_ATTRIBUTES]![]) +
            (value.Attributes[placement.Provider!""]![]) ]
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
                    "Key" : formatName(parts),
                    "Match" : namespaceObject.Match
                }
            ]
        ]
    [/#list]
    [#return namespaces]
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

    [#return asFlattenedSettings(getCompositeObject(["InhibitEnabled", { "Names" : "*" }], contexts)) ]
[/#function]

[#function internalGetOccurrenceSetting occurrence names emptyIfNotProvided=false]
    [#return getFirstSetting(
        [
            (occurrence.Configuration.Settings.Account)!{},
            (occurrence.Configuration.Settings.Product)!{},
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
                "REQUEST_REFERENCE" : commandLineOptions.References.Request,
                "CONFIGURATION_REFERENCE" : commandLineOptions.References.Configuration,
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
            (settingsObject.Settings.Accounts)!{},
            accountName,
            [""],
            alternatives) ]
[/#function]

[#function internalCreateOccurrenceBuildSettings occurrence]
    [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]
    [#local settingNamespaces = (occurrence.Configuration.Solution.SettingNamespaces)!{}]

    [#local alternatives =
        settingNamespaces?has_content?then(
            getSettingNamespaces(occurrence, settingNamespaces),
            []
        ) +
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#local occurrenceBuild =
        internalCreateOccurrenceSettings(
            (settingsObject.Builds.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives
        ) ]

    [#-- a local unit build commit/tag takes preference over a shared one --]
    [#local occurrenceBuildCommit = occurrenceBuild.COMMIT!{} ]
    [#local occurrenceBuildTag = occurrenceBuild.TAG!{} ]
    [#local occurrenceBuildFormats = occurrenceBuild.FORMATS!{} ]
    [#local occurrenceBuildScope = occurrenceBuild.SCOPE!{} ]

    [#-- Reference could be a deployment unit or a component --]
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
        [#local occurrenceBuild +=
            internalCreateOccurrenceSettings(
                (settingsObject.Builds.Products)!{},
                productName,
                buildLookupPrefixes,
                [
                    {"Key" : occurrenceBuild.REFERENCE.Value?replace("/","-"), "Match" : "exact"}
                ]
            ) ]
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
                {"Value" : (occurrenceBuild.REFERENCE.Value?replace("/","-"))!""},
                occurrenceBuild.REFERENCE!{},
                valueIfContent(
                    {"Value" : deploymentUnit},
                    deploymentUnit
                )
            )
        )
    ]
[/#function]

[#function internalCreateOccurrenceProductSettings occurrence ]
    [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]
    [#local settingNamespaces = (occurrence.Configuration.Solution.SettingNamespaces)!{}]

    [#local alternatives =
        settingNamespaces?has_content?then(
            getSettingNamespaces(occurrence, settingNamespaces),
            []
        ) +
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        internalCreateOccurrenceSettings(
            (settingsObject.Settings.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives) ]
[/#function]

[#function internalCreateOccurrenceSensitiveSettings occurrence]
    [#local deploymentUnit = getOccurrenceDeploymentUnit(occurrence) ]
    [#local settingNamespaces = (occurrence.Configuration.Solution.SettingNamespaces)!{}]

    [#local alternatives =
        settingNamespaces?has_content?then(
            getSettingNamespaces(occurrence, settingNamespaces),
            []
        ) +
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        markAsSensitiveSettings(
            internalCreateOccurrenceSettings(
                (settingsObject.Sensitive.Products)!{},
                productName,
                cmdbProductLookupPrefixes,
                alternatives) ) ]
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
