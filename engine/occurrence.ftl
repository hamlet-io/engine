[#ftl]

[#----------------------------------------------
-- Public functions for occurrence processing --
------------------------------------------------]

[#-- Get the occurrences of versions/instances of a component --]
[#function getOccurrences tier component ]
    [#return internalGetOccurrences(component, tier) ]
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

[#function getOccurrenceNetwork occurrence]
    [#return getTierNetwork(occurrence.Core.Tier.Id)]
[/#function]

[#function getOccurrenceFragmentBase occurrence]
    [#return contentIfContent((occurrence.Configuration.Solution.Fragment)!"", occurrence.Core.Component.Id)]
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

[#function getOccurrenceChildren occurrence]
    [#return (occurrence.Occurrences)![] ]
[/#function]

[#function hasOccurrenceChildren occurrence]
    [#return getOccurrenceChildren(occurrence)?has_content ]
[/#function]

[#function createOccurrenceFromExternalLink occurrence link]
    [#local targetOccurrence =
        {
            "Core" : {
                "External" : true,
                "Type" : link.Type!"external",
                "Tier" : {
                    "Id" : link.Tier,
                    "Name" : link.Tier
                },
                "Component" : {
                    "Id" : link.Component,
                    "Name" : link.Component
                },
                "Instance" : {
                    "Id" : "",
                    "Name" : ""
                },
                "Version" : {
                    "Id" : "",
                    "Name" : ""
                }
            },
            "Configuration" : {
                "Environment" : occurrence.Configuration.Environment
            },
            "State" : {
                "ResourceGroups" : {},
                "Attributes" : {}
            }
        }
    ]
    [#return
        targetOccurrence +
        {
            "State" : internalConstructOccurrenceState(targetOccurrence, {})
        }
    ]
[/#function]

[#--------------------------------------------------------
-- Internal support functions for occurrence processing --
----------------------------------------------------------]

[#function internalConstructOccurrenceAttributes occurrence]
    [#local attributes = [] ]

    [#list getComponentResourceGroups(occurrence.Core.Type) as key, value]
        [#local placement = (occurrence.State.ResourceGroups[key].Placement)!{}]
        [#local attributes +=
            value.Attributes[SHARED_ATTRIBUTES]![] +
            value.Attributes[placement.Provider!""]![]]
    [/#list]
    [#return attributes]
[/#function]

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
                              "Deployed" : getExistingReference(resource.Id)?has_content
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


[#function internalConstructOccurrenceState occurrence parentOccurrence]

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
        [#if invokeStateMacro(occurrence, key, parentOccurrence, state)]
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

[#function internalConstructOccurrenceSettings possibilities root prefixes alternatives]
    [#local contexts = [] ]

    [#-- Order possibilities in increasing priority --]
    [#list prefixes as prefix]
        [#list possibilities?keys?sort as key]
            [#local matchKey = key?lower_case?remove_ending("-asfile") ]
            [#local value = possibilities[key] ]
            [#if value?has_content]
                [#list alternatives as alternative]
                    [#local alternativeKey = formatName(root, prefix, alternative.Key) ]
                    [@debug
                        message=alternative.Match + " comparison of " + matchKey + " to " + alternativeKey
                        enabled=false
                    /]
                    [#if
                        (
                            ((alternative.Match == "exact") && (alternativeKey == matchKey)) ||
                            ((alternative.Match == "partial") && (alternativeKey?starts_with(matchKey)))
                        ) ]
                        [@debug
                            message=alternative.Match + " comparison of " + matchKey + " to " + alternativeKey + " successful"
                            enabled=false
                        /]
                        [#local contexts += [value] ]
                        [#break]
                    [/#if]
                [/#list]
            [/#if]
        [/#list]
    [/#list]
    [#return asFlattenedSettings(getCompositeObject({ "Names" : "*" }, contexts)) ]
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

[#function internalConstructOccurrenceCoreSettings occurrence]
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
                "REQUEST_REFERENCE" : requestReference,
                "CONFIGURATION_REFERENCE" : configurationReference,
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

[#function internalConstructAccountSettings ]
    [#local alternatives = [{"Key" : "shared", "Match" : "exact"}] ]

    [#-- Fudge prefixes for accounts --]
    [#return
        internalConstructOccurrenceSettings(
            (settingsObject.Settings.Accounts)!{},
            accountName,
            [""],
            alternatives) ]
[/#function]

[#function internalConstructOccurrenceBuildSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#local occurrenceBuild =
        internalConstructOccurrenceSettings(
            (settingsObject.Builds.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives
        ) ]

    [#-- a local unit build commit/tag takes preference over a shared one --]
    [#local occurrenceBuildCommit = occurrenceBuild.COMMIT!"" ]
    [#local occurrenceBuildTag = occurrenceBuild.TAG!"" ]

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
            internalConstructOccurrenceSettings(
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
            "BUILD_REFERENCE",
            valueIfContent(
                occurrenceBuildCommit,
                occurrenceBuildCommit,
                occurrenceBuild.COMMIT!{}
            )
        ) +
        attributeIfContent(
            "APP_REFERENCE",
            valueIfContent(
                occurrenceBuildTag,
                occurrenceBuildTag,
                occurrenceBuild.TAG!{}
            )
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

[#function internalConstructOccurrenceProductSettings occurrence ]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        internalConstructOccurrenceSettings(
            (settingsObject.Settings.Products)!{},
            productName,
            cmdbProductLookupPrefixes,
            alternatives) ]
[/#function]

[#function internalConstructOccurrenceSensitiveSettings occurrence]
    [#local deploymentUnit = (occurrence.Configuration.Solution.DeploymentUnits[0])!"" ]

    [#local alternatives =
        [
            {"Key" : deploymentUnit, "Match" : "exact"},
            {"Key" : occurrence.Core.Name, "Match" : "partial"},
            {"Key" : occurrence.Core.TypedName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortName, "Match" : "partial"},
            {"Key" : occurrence.Core.ShortTypedName, "Match" : "partial"}
        ] ]

    [#return
        markAsSensitiveSettings(
            internalConstructOccurrenceSettings(
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

[#-- treat the value "default" for version/instance as the same as blank --]
[#function getContextId context]
    [#return
        (context.Id == "default")?then(
            "",
            context.Id
        )
    ]
[/#function]

[#function getContextName context]
    [#return
        getContextId(context)?has_content?then(
            context.Name,
            ""
        )
    ]
[/#function]

[#-- Get the occurrences of versions/instances of a component           --]
[#-- This function should NOT be called directly - it is for the use of --]
[#-- other functions in this file                                       --]
[#function internalGetOccurrences component tier={} parentOccurrence={} parentContexts=[] componentType="" ]

    [#if !(component?has_content) ]
        [#return [] ]
    [/#if]

    [#local componentContexts = asArray(parentContexts) ]

    [#if tier?has_content]
        [#local type = getComponentType(component) ]
        [#local typeObject = getComponentTypeObject(component) ]
    [#else]
        [#local type = componentType ]
        [#local typeObject = component ]
    [/#if]

    [#-- Ensure we know the basic resource group information for the component --]
    [@includeSharedComponentConfiguration type /]

    [#if tier?has_content]
        [#local tierId = getTierId(tier) ]
        [#local tierName = getTierName(tier) ]
        [#local componentId = getComponentId(component) ]
        [#local componentName = getComponentName(component) ]
        [#local subComponentId = [] ]
        [#local subComponentName = [] ]
        [#local componentContexts += [component, typeObject] ]
    [#else]
        [#local tierId = parentOccurrence.Core.Tier.Id ]
        [#local tierName = parentOccurrence.Core.Tier.Name ]
        [#local componentId = parentOccurrence.Core.Component.Id ]
        [#local componentName = parentOccurrence.Core.Component.Name ]
        [#local subComponentId = typeObject.Id?split("-") ]
        [#local subComponentName = typeObject.Name?split("-") ]
        [#local componentContexts += [typeObject] ]
    [/#if]

    [#local occurrences=[] ]

    [#list typeObject.Instances!{"default" : {}} as instanceKey, instanceValue]
        [#if instanceValue?is_hash ]
            [#local instance = {"Id" : instanceKey, "Name" : instanceKey} + instanceValue]
            [#local instanceId = getContextId(instance) ]
            [#local instanceName = getContextName(instance) ]

            [#list instance.Versions!{"default" : {}} as versionKey, versionValue]
                [#if versionValue?is_hash ]
                    [#local version = {"Id" : versionKey, "Name" : versionKey} + versionValue]
                    [#local versionId = getContextId(version) ]
                    [#local versionName = getContextName(version) ]
                    [#local occurrenceContexts = componentContexts + [instance, version] ]
                    [#local idExtensions =
                                subComponentId +
                                asArray(instanceId, true, true) +
                                asArray(versionId, true, true) ]
                    [#local nameExtensions =
                                subComponentName +
                                asArray(instanceName, true, true) +
                                asArray(versionName, true, true) ]
                    [#local occurrence =
                        {
                            "Core" : {
                                "Type" : type,
                                "Tier" : {
                                    "Id" : tierId,
                                    "Name" : tierName
                                },
                                "Component" : {
                                    "Id" : componentId,
                                    "RawId" : component.Id,
                                    "Name" : componentName,
                                    "RawName" : component.Name,
                                    "Type" : type
                                },
                                "Instance" : {
                                    "Id" : firstContent(instanceId, (parentOccurrence.Core.Instance.Id)!""),
                                    "Name" : firstContent(instanceName, (parentOccurrence.Core.Instance.Name)!"")
                                },
                                "Version" : {
                                    "Id" : firstContent(versionId, (parentOccurrence.Core.Version.Id)!""),
                                    "Name" : firstContent(versionName, (parentOccurrence.Core.Version.Name)!"")
                                },
                                "Internal" : {
                                    "IdExtensions" : idExtensions,
                                    "NameExtensions" : nameExtensions
                                },
                                "Extensions" : {
                                    "Id" :
                                        ((parentOccurrence.Core.Extensions.Id)![tierId, componentId]) + idExtensions,
                                    "Name" :
                                        ((parentOccurrence.Core.Extensions.Name)![tierName, componentName]) + nameExtensions
                                }

                            } +
                            attributeIfContent(
                                "SubComponent",
                                subComponentId,
                                {
                                    "Id" : formatId(subComponentId),
                                    "Name" : formatName(subComponentName)
                                }
                            ),
                            "State" : {
                                "ResourceGroups" : {},
                                "Attributes" : {}
                            }
                        }
                    ]

                    [#-- Determine the occurrence deployment and placement profiles based on normal cmdb hierarchy --]
                    [#local profiles =
                        getCompositeObject(
                            coreProfileChildConfiguration,
                            occurrenceContexts).Profiles ]

                    [#-- Determine placement profile --]
                    [#local placementProfile = getPlacementProfile(profiles.Placement, segmentQualifiers) ]

                    [#-- Add resource group placements to the occurrence --]
                    [#list getComponentResourceGroups(type)?keys as key]
                        [#local occurrence =
                            mergeObjects(
                                occurrence,
                                {
                                    "State" : {
                                        "ResourceGroups" : {
                                            key : {
                                                "Placement" : getResourceGroupPlacement(key, placementProfile)
                                            }
                                        }
                                    }
                                }
                            ) ]
                    [/#list]

                    [#-- Ensure we have loaded the component configuration --]
                    [@includeComponentConfiguration
                        component=type
                        placements=occurrence.State.ResourceGroups /]

                    [#-- Determine the required attributes now the provider specific configuration is in place --]
                    [#local attributes = internalConstructOccurrenceAttributes(occurrence) ]

                    [#-- Apply deployment profile overrides --]
                    [#local occurrenceContexts +=
                        [
                            (getDeploymentProfile(profiles.Deployment, deploymentMode)[type])!{}
                        ]
                    ]

                    [#local occurrence +=
                        {
                            "Configuration" : {
                                "Solution" : getCompositeObject(attributes, occurrenceContexts)
                            }
                        }
                    ]

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
                                        "Build" : internalConstructOccurrenceBuildSettings(occurrence),
                                        "Account" : internalConstructAccountSettings(),
                                        "Product" :
                                            internalConstructOccurrenceProductSettings(occurrence) +
                                            internalConstructOccurrenceSensitiveSettings(occurrence)
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
                                        "Core" : internalConstructOccurrenceCoreSettings(occurrence)
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
                    [#local occurrence +=
                        {
                            "State" : internalConstructOccurrenceState(occurrence, parentOccurrence)

                        } ]
                    [#local subOccurrences = [] ]

                    [#list getComponentChildren(type) as subComponent]
                        [#-- Subcomponent instances can either be under a Components --]
                        [#-- attribute or directly under the subcomponent object.    --]
                        [#-- To cater for the latter case, any default configuration --]
                        [#-- must be under a "Configuration" attribute to avoid the  --]
                        [#-- configuration being treated as subcomponent instances.  --]
                        [#local subComponentInstances = {} ]
                        [#if ((typeObject[subComponent.Component])!{})?is_hash ]
                            [#local subComponentInstances =
                                (typeObject[subComponent.Component].Components)!
                                (typeObject[subComponent.Component])!{}
                            ]
                        [#else]
                            [@fatal
                              message="Subcomponent " + subComponent.Component + " content is not a hash"
                              context=typeObject[subComponent.Component] /]
                        [/#if]

                        [#list subComponentInstances as key,subComponentInstance ]
                            [#if subComponentInstance?is_hash ]
                                [#if
                                    (!((typeObject[subComponent.Component].Components)?has_content)) &&
                                    (key == "Configuration") ]
                                    [#continue]
                                [/#if]
                                [#local
                                    subOccurrences +=
                                        internalGetOccurrences(
                                            {
                                                "Id" : key,
                                                "Name" : key
                                            } +
                                                subComponentInstance,
                                            {},
                                            occurrence,
                                            occurrenceContexts +
                                                [
                                                    typeObject[subComponent.Component],
                                                    typeObject[subComponent.Component].Configuration!{}
                                                ],
                                            subComponent.Type
                                        )
                                ]
                            [/#if]
                        [/#list]
                    [/#list]

                    [#local occurrences +=
                        [
                            occurrence +
                            attributeIfContent("Occurrences", subOccurrences)
                        ]
                    ]
                [/#if]
            [/#list]
        [/#if]
    [/#list]

    [#return occurrences ]
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
