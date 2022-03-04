[#ftl]

[#-- Registry definitions --]

[#function getRegistryEndpointValue occurrence qualifiers ]

    [#return
        contentIfContent(
            getOccurrenceSettingValue(
                occurrence, asFlattenedArray(["Registries", qualifiers, "Endpoint"]), true),
            getOccurrenceSettingValue(
                    occurrence, asFlattenedArray(["Registries", qualifiers, "Registry"]), true)
        )
    ]
[/#function]


[#function getRegistryEndPoint type occurrence region="" ]

    [#if !(region?has_content) ]
        [#local region = occurrence.State.ResourceGroups["default"].Placement.Region ]
    [/#if]

    [#return
        contentIfContent(
            getRegistryEndpointValue(occurrence, [type, "RegionEndpoints", region]),
            contentIfContent(
                getRegistryEndpointValue(occurrence, [type ]),
                "HamletFatal: Unknown registry of type " + type
            )
        )
    ]
[/#function]

[#function getRegistryPrefix type occurrence ]
    [#return getOccurrenceSettingValue(occurrence, ["Registries", type, "Prefix"], true) ]
[/#function]

[#-- Environment Variable Management --]
[#function addVariableToContext context name value upperCase=true]
    [#return
        mergeObjects(
            context,
            {
                "Environment" : {
                    formatSettingName(upperCase, name) : asSerialisableString(value)
                }
            }
        ) ]
[/#function]

[#function addLinkVariablesToContext context name link attributes rawName=false ignoreIfNotDefined=false requireLinkAttributes=false ]
    [#local result = context ]
    [#local linkAttributes = (context.Links[link].State.Attributes)!{} ]
    [#local attributeList = valueIfContent(asArray(attributes), attributes, linkAttributes?keys) ]
    [#if linkAttributes?has_content]
        [#list attributeList as attribute]
            [#local variableName = name + valueIfTrue("_" + attribute, !rawName, "") ]
            [#if (linkAttributes[attribute?upper_case])??]
                [#local result =
                    addVariableToContext(
                        result,
                        variableName,
                        linkAttributes[attribute?upper_case]) ]
            [#else]
                [#if !ignoreIfNotDefined]
                   [#local result = addVariableToContext(result, variableName, "HamletFatal: Attribute " + attribute?upper_case + " not found for link " + link) ]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#if requireLinkAttributes ]
            [#if ignoreIfNotDefined]
                [#local result = addVariableToContext(result, name, "Ignoring link " + link) ]
            [#else]
                [#local result = addVariableToContext(result, name, "HamletFatal: No attributes found for link " + link) ]
            [/#if]
        [/#if]
    [/#if]
    [#return result]
[/#function]

[#function getDefaultLinkVariables links includeInbound=false]
    [#local result = {"Links" : links, "Environment": {} }]
    [#list links as name,value]
        [#if (value.Direction?lower_case != "inbound") || includeInbound]
            [#local result = addLinkVariablesToContext(result, name, name, value.IncludeInContext, false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]

[#function getDefaultBaselineVariables links={} ]
    [#local result = {"Links" : links, "Environment": {} }]
    [#list links as name,value]
        [#if (value.Direction?lower_case != "inbound") || includeInbound]
            [#local result = addLinkVariablesToContext(result, name, name, [], false, false, false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]


[#function defaultEnvironment occurrence links baselineLinks={}]
    [#return
        occurrence.Configuration.Environment.General +
        occurrence.Configuration.Environment.Build +
        occurrence.Configuration.Environment.Sensitive +
        occurrence.Configuration.Environment.Component +
        getDefaultLinkVariables(links, true) +
        baselineLinks?has_content?then(
            getDefaultBaselineVariables(baselineLinks),
            {}
        )
    ]
[/#function]

[#function getFinalEnvironment occurrence context environmentSettings={}]
    [#local asFile = environmentSettings.AsFile!false]
    [#local serialisationConfig = environmentSettings.Json!{}]

    [#local hasBaselineLinks = (context.BaselineLinks!{})?has_content]

    [#local operationsBucket = hasBaselineLinks?then(
                                context.BaselineLinks["OpsData"].State.Attributes["BUCKET"]!"HamletFatal: asFile configured but could not find opsBucket",
                                ""
    )]

    [#local asFileFormat = (environmentSettings.FileFormat)!"json" ]
    [#switch asFileFormat ]
        [#case "json" ]
            [#local asFileSuffix = ".json"]
            [#break]
        [#case "yaml"]
            [#local asFileSuffix = ".yaml"]
            [#break]
    [/#switch]

    [#local runId = getCLORunId()]
    [#-- Link attributes can be overridden by build and product settings, and --]
    [#-- anything can be overridden if explicitly defined via fragments --]
    [#return
        {
            "Environment" :
                valueIfTrue(
                    getSettingsAsEnvironment(
                        occurrence.Configuration.Settings.Core,
                        serialisationConfig
                    ),
                    context.DefaultCoreVariables || asFile
                ) +
                valueIfTrue(
                    {
                        "SETTINGS_FILE" : ["s3:/", operationsBucket, getSettingsFilePrefix(occurrence), "config/config_" + runId + asFileSuffix ]?join("/"),
                        "RUN_ID" : runId
                    },
                    ( asFile && hasBaselineLinks),
                    valueIfTrue(
                        getDefaultLinkVariables(context.Links),
                        context.DefaultLinkVariables
                    ) +
                    valueIfTrue(
                        getDefaultBaselineVariables(context.BaselineLinks),
                        ( context.DefaultBaselineVariables && hasBaselineLinks )
                    ) +
                    valueIfTrue(
                        getSettingsAsEnvironment(
                            occurrence.Configuration.Settings.Component,
                            serialisationConfig
                        ),
                        context.DefaultComponentVariables
                    ) +
                    valueIfTrue(
                        getSettingsAsEnvironment(occurrence.Configuration.Settings.Build) +
                        { "RUN_ID" : runId },
                        context.DefaultCoreVariables
                    ) +
                    valueIfTrue(
                        getSettingsAsEnvironment(
                            occurrence.Configuration.Settings.Product,
                            serialisationConfig
                        )
                        context.DefaultEnvironmentVariables
                    ) +
                    context.Environment +
                    valueIfTrue(
                        context.ContextSettings!{},
                        ( context.ContextSettings?has_content && ! (serialisationConfig.Escaped)!true),
                        {}
                    )
                )
        } ]
[/#function]

[#-- Shared Task processing for ECS and containers --]
[#function getContainerId container]
    [#return container?is_hash?then(
                container.Id?split("-")[0],
                container?split("-")[0])]
[/#function]

[#function getContainerName container]
    [#return container.Name?split("-")[0]]
[/#function]

[#function getContainerMode container]
    [#if container?is_hash && (container.RunMode!"")?has_content ]
        [#return container.RunMode ]
    [#else]
        [#local idParts = container?is_hash?then(
                            container.Id?split("-"),
                            container?split("-"))]
        [#return idParts[1]?has_content?then(
                    idParts[1]?upper_case,
                    "WEB")]
    [/#if]
[/#function]
