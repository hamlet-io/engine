[#ftl]

[#-- Functions --]

[#function getRegistryEndPoint type occurrence ]
    [#return
        contentIfContent(
            getOccurrenceSettingValue(
                occurrence, ["Registries", type, "Endpoint"], true),
            contentIfContent(
                getOccurrenceSettingValue(
                    occurrence, ["Registries", type, "Registry"], true),
                "COTException: Unknown registry of type " + type
            )
        ) ]
[/#function]

[#function getRegistryPrefix type occurrence ]
    [#return getOccurrenceSettingValue(occurrence, ["Registries", type, "Prefix"], true) ]
[/#function]

[#function getContainerId container]
    [#return container?is_hash?then(
                container.Id?split("-")[0],
                container?split("-")[0])]
[/#function]

[#function getContainerName container]
    [#return container.Name?split("-")[0]]
[/#function]

[#function getContainerMode container]
    [#assign idParts = container?is_hash?then(
                        container.Id?split("-"),
                        container?split("-"))]
    [#return idParts[1]?has_content?then(
                idParts[1]?upper_case,
                "WEB")]
[/#function]

[#-- Container List Macros --]

[#macro Attributes name="" image="" version="" essential=true]
    [#if (containerListMode!"") == "model"]
        [#assign context +=
            {
                "Essential" : essential
            } +
            attributeIfContent("Name", name) +
            attributeIfContent("Image", image) +
            attributeIfContent("ImageVersion", version)
        ]
    [/#if]
[/#macro]

[#function addVariableToContext context name value]
    [#return
        setDescendent(
            context,
            (value?is_hash || value?is_sequence)?then(getJSON(value, true), value),
            formatSettingName(name)
            "Environment") ]
[/#function]

[#macro Variable name value]
    [#if (containerListMode!"") == "model"]
        [#assign context = addVariableToContext(context, name, value) ]
    [/#if]
[/#macro]

[#function getLinkResourceId link alias]
    [#return (context.Links[link].State.Resources[alias].Id)!"" ]
[/#function]

[#function addLinkVariablesToContext context name link attributes rawName=false ignoreIfNotDefined=false]
    [#local result = context ]
    [#local linkAttributes = (context.Links[link].State.Attributes)!{} ]
    [#local attributeList = valueIfContent(asArray(attributes), attributes, linkAttributes?keys) ]
    [#if linkAttributes?has_content]
        [#list attributeList as attribute]
            [#local result =
                addVariableToContext(
                    result,
                    name + valueIfTrue("_" + attribute, !rawName, ""),
                    (linkAttributes[attribute?upper_case])!"") ]
        [/#list]
    [#else]
        [#if ignoreIfNotDefined]
            [#local result = addVariableToContext(result, name, "Ignoring link " + link) ]
        [#else]
            [#local result = addVariableToContext(result, name, "COTException: No attributes found for link " + link) ]
        [/#if]
    [/#if]
    [#return result]
[/#function]

[#function getDefaultLinkVariables context]
    [#local result = context + {"Environment": {} }]
    [#list context.Links as name,value]
        [#if value.Direction != "inbound"]
            [#local result = addLinkVariablesToContext(result, name, name, [], false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]

[#macro Link name link="" attributes=[] rawName=false ignoreIfNotDefined=false]
    [#if (containerListMode!"") == "model"]
        [#assign context =
            addLinkVariablesToContext(
                context,
                name,
                contentIfContent(link, name),
                attributes,
                rawName,
                ignoreIfNotDefined) ]
    [/#if]
[/#macro]

[#macro DefaultLinkVariables enabled=true ]
    [#if (containerListMode!"") == "model"]
        [#assign context += { "DefaultLinkVariables" : enabled } ]
    [/#if]
[/#macro]

[#macro DefaultCoreVariables enabled=true ]
    [#if (containerListMode!"") == "model"]
        [#assign context += { "DefaultCoreVariables" : enabled } ]
    [/#if]
[/#macro]

[#macro DefaultEnvironmentVariables enabled=true ]
    [#if (containerListMode!"") == "model"]
        [#assign context += { "DefaultEnvironmentVariables" : enabled } ]
    [/#if]
[/#macro]

[#function getFragmentSettingValue key value asBoolean=false]
    [#if value?is_hash]
        [#local name = contentIfContent(value.Setting!"", key) ]

        [#if value.IgnoreIfMissing!false &&
            !(context.DefaultEnvironment[formatSettingName(name)])?? ]
                [#return valueIfTrue(false, asBoolean, "") ]
        [/#if]
    [#else]
        [#if value?is_string]
            [#local name = value]
        [#else]
            [#return valueIfTrue(true, asBoolean, "COTException: Value for " + key + " must be a string or hash") ]
        [/#if]
    [/#if]

    [#return
        valueIfTrue(
            true,
            asBoolean,
            context.DefaultEnvironment[formatSettingName(name)]!
                "COTException: Variable " + name + " not found"
        ) ]
[/#function]

[#macro AltSettings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [#if getFragmentSettingValue(key, value, true)]
                    [@Variable name=key value=getFragmentSettingValue(key, value) /]
                [/#if]
            [/#list]
        [/#if]
        [#if setting?is_string]
            [@Variable name=setting value=getFragmentSettingValue(setting, setting) /]
        [/#if]
    [/#list]
[/#macro]

[#macro Settings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [@Variable name=key value=value /]
            [/#list]
        [/#if]
        [#if setting?is_string]
            [@Variable name=setting value=getFragmentSettingValue(setting, setting) /]
        [/#if]
    [/#list]
[/#macro]

[#macro Variables variables...]
    [@Settings  variables /]
[/#macro]

[#macro Host name value]
    [#if (containerListMode!"") == "model"]
        [#assign context +=
            {
                "Hosts" : (context.Hosts!{}) + { name : value }
            }
        ]
    [/#if]
[/#macro]

[#macro Hosts hosts]
    [#if ((containerListMode!"") == "model") && hosts?is_hash]
        [#assign context +=
            {
                "Hosts" : (context.Hosts!{}) + hosts
            }
        ]
    [/#if]
[/#macro]

[#macro Volume name containerPath hostPath="" readOnly=false]
    [#if (containerListMode!"") == "model"]
        [#assign context +=
            {
                "Volumes" :
                    (context.Volumes!{}) +
                    {
                        name : {
                            "ContainerPath" : containerPath,
                            "HostPath" : hostPath,
                            "ReadOnly" : readOnly
                        }
                    }
            }
        ]
    [/#if]
[/#macro]

[#macro Volumes volumes]
    [#if ((containerListMode!"") == "model") && volumes?is_hash]
        [#assign context +=
            {
                "Volumes" : (context.Volumes!{}) + volumes
            }
        ]
    [/#if]
[/#macro]

[#macro Policy statements...]
    [#if (containerListMode!"") == "model"]
        [#assign context +=
            {
                "Policy" : (context.Policy![]) + asFlattenedArray(statements)
            }
        ]
    [/#if]
[/#macro]

[#assign ECS_DEFAULT_MEMORY_LIMIT_MULTIPLIER=1.5 ]

[#function defaultEnvironment occurrence mode=""]
    [#return
        occurrence.Configuration.Environment.General +
        attributeIfContent("APP_RUN_MODE", mode) +
        occurrence.Configuration.Environment.Build +
        occurrence.Configuration.Environment.Sensitive
    ]
[/#function]

[#function standardPolicies occurrence ]
    [#local permissions = occurrence.Configuration.Solution.Permissions ]
    [#return
        valueIfTrue(
            credentialsDecryptPermission(),
            permissions.Decrypt,
            []
        ) +
        valueIfTrue(
            s3ReadPermission(operationsBucket, getSettingsFilePrefix(occurrence)),
            permissions.AsFile,
            []
        ) +
        valueIfTrue(
            s3AllPermission(dataBucket, getAppDataFilePrefix(occurrence)),
            permissions.AppData,
            []
        ) +
        valueIfTrue(
            s3AllPermission(dataBucket, getAppDataPublicFilePrefix(occurrence)),
            permissions.AppPublic && getAppDataPublicFilePrefix(occurrence)?has_content,
            []
        )
    ]
[/#function]

[#function getFinalEnvironment occurrence context ]
    [#return
        {
            "Environment" :
                valueIfTrue(
                    getSettingsAsEnvironment(occurrence.Configuration.Settings.Core) +
                    getSettingsAsEnvironment(occurrence.Configuration.Settings.Build),
                    context.DefaultCoreVariables
                ) +
                valueIfTrue(
                    context.DefaultEnvironment,
                    context.DefaultEnvironmentVariables
                ) +
                valueIfTrue(
                    getDefaultLinkVariables(context),
                    context.DefaultLinkVariables
                ) +
                context.Environment
        } ]
[/#function]

[#function getTaskContainers ecs task]

    [#local core = task.Core ]
    [#local solution = task.Configuration.Solution ]

    [#local tier = core.Tier ]
    [#local component = core.Component ]

    [#local containers = [] ]

    [#list solution.Containers?values as container]
        [#local containerPortMappings = [] ]
        [#local containerLinks = container.Links ]
        [#list container.Ports?values as port]

            [#local lbLink = getLBLink( task, port )]
            [#local containerLinks += lbLink]

            [#local containerPortMapping =
                {
                    "ContainerPort" :
                        contentIfContent(
                            port.Container!"",
                            port.Id
                        ),
                    "HostPort" : port.Id,
                    "DynamicHostPort" : port.DynamicHostPort
                } ]

            [#if lbLink[port.LB.LinkName]?has_content ]
                [#local loadBalancer = lbLink[port.LB.LinkName]]
                [#local containerPortMapping +=
                    {
                        "LoadBalancer" :
                            {
                                "Link" : loadBalancer.Name,
                                "TargetGroup" : loadBalancer.TargetGroup,
                                "Priority" : port.LB.Priority,
                                "Path" : loadBalancer.TargetPath
                            }
                    }
                ]
            [/#if]
            [#local containerPortMappings += [containerPortMapping] ]
        [/#list]

        [#local logDriver =
            valueIfTrue(
                "json-file",
                container.LocalLogging,
                container.LogDriver
            ) ]

        [#local containerLgId =
            formatDependentLogGroupId(core.Id,  container.Id?split("-")) ]
        [#local containerLgName =
            formatAbsolutePath(core.FullAbsolutePath, container.Name?split("-")) ]
        [#local containerLogGroup =
            valueIfTrue(
                {
                    "Id" : containerLgId,
                    "Name" : containerLgName
                },
                container.ContainerLogGroup
            ) ]

        [#local logGroupId =
            valueIfTrue(
                containerLgId,
                container.ContainerLogGroup,
                valueIfTrue(
                    resources["lg"].Id!"",
                    solution.TaskLogGroup,
                    valueIfTrue(
                        ecs.State.Resources["lg"].Id!"",
                        ecs.Configuration.Solution.ClusterLogGroup,
                        "COTException: Logs type is awslogs but no group defined"
                    )
                )
            ) ]

        [#local logOptions =
            logDriver?switch(
                "fluentd",
                {
                    "tag" : concatenate(
                                [
                                    "docker",
                                    productId,
                                    segmentId,
                                    tier.Id,
                                    component.Id,
                                    container.Id
                                ],
                                "."
                            )
                },
                "awslogs",
                {
                    "awslogs-group" : getReference(logGroupId),
                    "awslogs-region" : regionId,
                    "awslogs-stream-prefix" : core.Name
                },
                {}
            )]

        [#assign context =
            {
                "Id" : getContainerId(container),
                "Name" : getContainerName(container),
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "Essential" : true,
                "RegistryEndPoint" : getRegistryEndPoint("docker", task),
                "Image" :
                    formatRelativePath(
                        productName,
                        formatName(
                            getOccurrenceBuildUnit(task),
                            getOccurrenceBuildReference(task)
                        )
                    ),
                "MemoryReservation" : container.MemoryReservation,
                "Mode" : getContainerMode(container),
                "LogDriver" : logDriver,
                "LogOptions" : logOptions,
                "DefaultEnvironment" :
                    defaultEnvironment(task, getContainerMode(container)) +
                    {
                        "AWS_REGION" : regionId,
                        "AWS_DEFAULT_REGION" : regionId
                    },
                "Environment" : {},
                "Links" : getLinkTargets(task, containerLinks),
                "DefaultCoreVariables" : true,
                "DefaultEnvironmentVariables" : true,
                "DefaultLinkVariables" : true,
                "Policy" : standardPolicies(task)
            } +
            attributeIfContent("LogGroup", containerLogGroup) +
            attributeIfContent("ImageVersion", container.Version) +
            attributeIfContent("Cpu", container.Cpu) +
            attributeIfTrue(
                "MaximumMemory",
                container.MaximumMemory?has_content &&
                    container.MaximumMemory?is_number &&
                    container.MaximumMemory > 0,
                container.MaximumMemory!""
            ) +
            attributeIfTrue(
                "MaximumMemory",
                !container.MaximumMemory??,
                container.MemoryReservation*ECS_DEFAULT_MEMORY_LIMIT_MULTIPLIER
            ) +
            attributeIfContent("PortMappings", containerPortMappings)
        ]

        [#-- Add in container specifics including override of defaults --]
        [#assign containerListMode = "model"]
        [#assign containerId = formatContainerFragmentId(task, container)]
        [#include containerList]

        [#assign context += getFinalEnvironment(task, context) ]

        [#local containers += [context] ]
    [/#list]

    [#return containers]
[/#function]
