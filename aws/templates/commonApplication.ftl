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
                "Exception: Unknown registry of type " + type
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

[#function addLinkVariablesToContext context name link attributes rawName=false]
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
        [#local result = addVariableToContext(result, name, "Exception: No attributes found") ]
    [/#if]
    [#return result]
[/#function]

[#function addDefaultLinkVariablesToContext context]
    [#local result = context ]
    [#list context.Links?keys as name]
        [#local result = addLinkVariablesToContext(result, name, name, [], false) ]
    [/#list]
    [#return result]
[/#function]

[#macro Link name link attributes=[] rawName=false]
    [#if (containerListMode!"") == "model"]
        [#assign context =
            addLinkVariablesToContext(context, name, link, attributes, rawName) ]
    [/#if]
[/#macro]

[#macro DefaultLinkVariables enabled=true ]
    [#if (containerListMode!"") == "model"]
        [#assign context += { "DefaultLinkVariables" : enabled } ]
    [/#if]
[/#macro]

[#macro AltSettings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [@Variable
                    name=key
                    value=context.Environment[formatSettingName(value)]!"Exception: Alternate variable " + formatSettingName(value) + " not found." /]
            [/#list]
        [/#if]
    [/#list]
[/#macro]

[#macro Settings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_hash]
            [#list setting as key,value]
                [@Variable
                    name=key
                    value=value /]
            [/#list]
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

[#macro Volume name containerPath hostPath="" readonly=false]
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

[#function standardEnvironment occurrence mode=""]
    [#return
        occurrence.Configuration.Environment.General +
        occurrence.Configuration.Environment.Sensitive +
        attributeIfContent("APP_RUN_MODE", mode)
    ]
[/#function]

[#function getTaskContainers task]

    [#local core = task.Core ]
    [#local solution = task.Configuration.Solution ]

    [#local tier = core.Tier ]
    [#local component = core.Component ]

    [#local containers = [] ]

    [#list solution.Containers?values as container]
        [#local containerPortMappings = [] ]
        [#local containerLinks = container.Links ]
        [#list container.Ports?values as port]
            [#local targetLoadBalancer = {} ]
            [#local targetTierId = (port.LB.Tier)!"elb" ]
            [#local targetComponentId = (port.LB.Component)!port.ELB ]
            [#local targetLinkName = port.LB.LinkName ]
            [#local targetSource =
                contentIfContent(
                    port.LB.Port,
                    valueIfContent(
                        (portMappings[port.LB.PortMapping].Source)!"",
                        port.LB.PortMapping,
                        port.Id
                    )
                ) ]

            [#-- Need to be careful to allow an empty value for --]
            [#-- Instance/Version to be explicitly provided and --]
            [#-- correctly handled in getLinkTarget             --]
            [#local targetLink =
                {
                    "Id" : targetLinkName,
                    "Name" : targetLinkName,
                    "Tier" : targetTierId,
                    "Component" : targetComponentId
                } +
                attributeIfTrue("Instance", port.LB.Instance??, port.LB.Instance!"") +
                attributeIfTrue("Version", port.LB.Version??, port.LB.Version!"") +
                attributeIfContent(
                    "Port",
                    valueIfTrue(targetSource, port.LB.Configured, "")
                )
            ]

            [@cfDebug listMode targetLink false /]

            [#if targetTierId?has_content && targetComponentId?has_content]
                [#local targetLoadBalancer = getLinkTarget(task, targetLink) ]

                [@cfDebug listMode targetLoadBalancer false /]

                [#if targetLoadBalancer?has_content ]

                    [#local targetGroup = port.LB.TargetGroup]
                    [#local targetPath = port.LB.Path]

                    [#if targetLoadBalancer.Core.Type == "alb" ]
                        [#if targetPath?has_content]
                            [#-- target group name must be provided if path provided --]
                            [#if !targetGroup?has_content]
                                [@cfException
                                    listMode "No target group for provided path" occurrence /]
                                [#local targetGroup = "default" ]
                            [/#if]
                        [#else]
                            [#if !targetGroup?has_content]
                                [#-- Create target group for container if it --]
                                [#-- is versioned and load balancer isn't    --]
                                [#if core.Version.Name?has_content &&
                                        !targetLoadBalancer.Core.Version.Name?has_content]
                                    [#local targetPath = "/" + core.Version.Name + "/*" ]
                                    [#local targetGroup = core.Version.Name ]
                                [#else]
                                    [#local targetGroup = "default" ]
                                [/#if]
                            [/#if]
                        [/#if]
                    [/#if]

                    [#local containerLinks += { targetLinkName : targetLink } ]
                [/#if]
            [/#if]

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
            [#if targetLoadBalancer?has_content]
                [#local containerPortMapping +=
                    {
                        "LoadBalancer" :
                            {
                                "Link" : targetLinkName,
                                "TargetGroup" : targetGroup,
                                "Priority" : port.LB.Priority,
                                "Path" : targetPath
                            }
                    }
                ]
            [/#if]
            [#local containerPortMappings += [containerPortMapping] ]
        [/#list]

        [#local dockerLogDriver = getOccurrenceSettingValue(task, "DOCKER_LOG_DRIVER", true) ]
        [#local dockerLocalLogging =
            contentIfContent(
                getOccurrenceSettingValue(task, "DOCKER_LOCAL_LOGGING", true),
                false) ]

        [#local logDriver =
            (container.LogDriver)!
            contentIfContent(
                dockerLogDriver,
                valueIfTrue(
                    "json-file",
                    dockerLocalLogging || container.LocalLogging,
                    "awslogs"
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
                    "awslogs-group":
                        getReference(formatComponentLogGroupId(tier, component)),
                    "awslogs-region": regionId,
                    "awslogs-stream-prefix": formatName(task)
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
                            buildDeploymentUnit,
                            getOccurrenceBuildReference(task)
                        )
                    ),
                "MemoryReservation" : container.MemoryReservation,
                "Mode" : getContainerMode(container),
                "LogDriver" : logDriver,
                "LogOptions" : logOptions,
                "Environment" :
                    standardEnvironment(task, getContainerMode(container)) +
                    {
                        "AWS_REGION" : regionId,
                        "AWS_DEFAULT_REGION" : regionId
                    },
                "Links" : getLinkTargets(task, containerLinks),
                "DefaultLinkVariables" : true
            } +
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

        [#if context.DefaultLinkVariables]
            [#assign context = addDefaultLinkVariablesToContext(context) ]
        [/#if]

        [#local containers += [context] ]
    [/#list]

    [@cfDebug listMode containers false /]

    [#return containers]
[/#function]
