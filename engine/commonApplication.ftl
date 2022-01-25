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

[#function standardPolicies occurrence baselineIds ]
    [#local permissions = occurrence.Configuration.Solution.Permissions ]
    [#return
        valueIfTrue(
            cmkDecryptPermission(baselineIds["Encryption"]),
            permissions.Decrypt,
            []
        ) +
        valueIfTrue(
            s3ReadPermission(baselineIds["OpsData"], getSettingsFilePrefix(occurrence)) +
            s3ListPermission(baselineIds["OpsData"], getSettingsFilePrefix(occurrence)) +
            s3EncryptionReadPermission(
                baselineIds["Encryption"],
                getExistingReference(baselineIds["OpsData"], NAME_ATTRIBUTE_TYPE),
                getSettingsFilePrefix(occurrence),
                getExistingReference(baselineIds["OpsData"], REGION_ATTRIBUTE_TYPE)
            ),
            permissions.AsFile,
            []
        ) +
        valueIfTrue(
            s3AllPermission(baselineIds["AppData"], getAppDataFilePrefix(occurrence)) +
            s3EncryptionAllPermission(
                baselineIds["Encryption"],
                getExistingReference(baselineIds["AppData"], NAME_ATTRIBUTE_TYPE),
                getAppDataFilePrefix(occurrence),
                getExistingReference(baselineIds["AppData"], REGION_ATTRIBUTE_TYPE)
            ),
            permissions.AppData,
            []
        ) +
        valueIfTrue(
            s3AllPermission(baselineIds["AppData"], getAppDataPublicFilePrefix(occurrence)) +
            s3EncryptionAllPermission(
                baselineIds["Encryption"],
                getExistingReference(baselineIds["AppData"], NAME_ATTRIBUTE_TYPE),
                getAppDataPublicFilePrefix(occurrence),
                getExistingReference(baselineIds["AppData"], REGION_ATTRIBUTE_TYPE)
            ),
            permissions.AppPublic && getAppDataPublicFilePrefix(occurrence)?has_content,
            []
        )
    ]
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

[#assign ECS_DEFAULT_MEMORY_LIMIT_MULTIPLIER=1.5 ]

[#function getTaskContainers ecs task]

    [#local core = task.Core ]
    [#local solution = task.Configuration.Solution ]

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(task, [ "OpsData", "AppData", "Encryption" ] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]

    [#local operationsBucket = getExistingReference(baselineComponentIds["OpsData"]) ]
    [#local dataBucket = getExistingReference(baselineComponentIds["AppData"])]

    [#local tier = core.Tier ]
    [#local component = core.Component ]

    [#local containers = [] ]

    [#list solution.Containers as containerId, container]
        [#local containerPortMappings = [] ]
        [#local containerLinks = mergeObjects( solution.Links, container.Links) ]
        [#local inboundPorts = []]
        [#local ingressRules = []]
        [#local egressRules = []]

        [#list container.Ports?values as port]

            [#local containerPortMapping =
                {
                    "ContainerPort" :
                        contentIfContent(
                            port.Container!"",
                            port.Name
                        ),
                    "HostPort" : port.Name,
                    "DynamicHostPort" : port.DynamicHostPort
                } ]

            [#if port.LB.Configured]
                [#local lbLink = getLBLink( task, port )]

                [#if isDuplicateLink(containerLinks, lbLink) ]
                    [@fatal
                        message="Duplicate Link Name"
                        context=containerLinks
                        detail=lbLink /]
                    [#continue]
                [/#if]

                [#-- Treat the LB link like any other - this will also detect --]
                [#-- if the target is missing                                 --]
                [#local containerLinks += lbLink]

                [#-- Ports should only be defined if connecting to a load balancer --]
                [#list lbLink as key,loadBalancer]
                    [#local containerPortMapping +=
                        {
                            "LoadBalancer" :
                                {
                                    "Link" : loadBalancer.Name
                                }
                        }
                    ]

                [/#list]

            [/#if]

            [#if port.Registry.Configured]
                [#local registryLink = getRegistryLink(task, port)]

                [#if isDuplicateLink(containerLinks, registryLink) ]
                    [@fatal
                        message="Duplicate Link Name"
                        context=containerLinks
                        detail=RegistryLink /]
                    [#continue]
                [/#if]

                [#-- Add to normal container links --]

                [#local containerLinks += registryLink]

                [#list registryLink as key,serviceRegistry]
                    [#local containerPortMapping +=
                        {
                            "ServiceRegistry" :
                                {
                                    "Link" : serviceRegistry.Name
                                }
                        }
                    ]

                [/#list]
            [/#if]

            [#if port.IPAddressGroups?has_content]
                [#if solution.NetworkMode == "awsvpc" || !port.LB.Configured ]
                    [#list getGroupCIDRs(port.IPAddressGroups, true, task ) as cidr]
                        [#local ingressRules += [ {
                            "port" : port.DynamicHostPort?then(0,contentIfContent(
                                                                            port.Container!"",
                                                                            port.Name )),
                            "cidr" : cidr
                        }]]
                    [/#list]
                [#else]
                    [@fatal
                        message="Port IP Address Groups not supported for port configuration"
                        context=container
                        detail=port /]
                    [#continue]
                [/#if]
            [/#if]

            [#local containerPortMappings += [containerPortMapping] ]
            [#local inboundPorts += [ port.Name ]]
        [/#list]

        [#local logDriver =
            valueIfTrue(
                "json-file",
                container.LocalLogging,
                container.LogDriver
            ) ]

        [#if logDriver != "awslogs" && solution.Engine == "fargate" ]
            [@fatal
                message="The fargate engine only supports the awslogs logging driver"
                context=solution
                /]
            [#break]
        [/#if]

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
                    task.State.Resources["lg"].Id!"",
                    solution.TaskLogGroup,
                    valueIfTrue(
                        ecs.State.Resources["lg"].Id!"",
                        ecs.Configuration.Solution.ClusterLogGroup,
                        "HamletFatal: Logs type is awslogs but no group defined"
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
                    "awslogs-region" : getRegion(),
                    "awslogs-stream-prefix" : core.Name
                },
                {}
            )]

        [#local contextLinks = getLinkTargets(task, containerLinks) ]

        [#local containerDetails = {
            "Id" : contentIfContent(
                    (container.Extensions[0])!"",
                    getContainerId(container)
            ),
            "Name" : getContainerName(container)
        }]

        [#-- Add in extension specifics including override of defaults --]
        [#-- Extensions are based on occurrences so we need to create a fake occurrence --]

        [#-- add an extra setting namespace which is used to find the container build refernces when images --]
        [#-- are manged by a container registry --]
        [#local containerSettingNamespaces = combineEntities(
            task.Configuration.SettingNamespaces,
            [
                {
                    "Key" : formatName(task.Core.RawName, containerId)?lower_case,
                    "Match" : "partial"
                }
            ],
            APPEND_COMBINE_BEHAVIOUR
        )]
        [#local containerBuildSettings = getAdditionalBuildSettings(containerSettingNamespaces)]

        [#local containerOccurrence = mergeObjects(
            task,
            {
                "Configuration" : {
                    "SettingNamespaces" : containerSettingNamespaces
                }
            }
        )]
        [#local containerOccurrence = mergeObjects(
            containerOccurrence,
            {
                "Configuration" : {
                    "Settings" : {
                        "Build" : containerBuildSettings
                    },
                    "Environment" : {
                        "Build" : getSettingsAsEnvironment(containerBuildSettings)
                    }
                }
            }
        )]

        [#local _context =
            containerDetails +
            {
                "Essential" : true,
                "RegistryEndPoint" : getRegistryEndPoint("docker", task),
                "Image" : formatRelativePath(
                    formatName(
                        getOccurrenceBuildProduct(task, productName),
                        getOccurrenceBuildScopeExtension(task)
                    ),
                    formatName(
                        getOccurrenceBuildUnit(task),
                        getOccurrenceBuildReference(task)
                    )
                ),
                "MemoryReservation" : container.MemoryReservation,
                "Mode" : getContainerMode(container),
                "LogDriver" : logDriver,
                "LogOptions" : logOptions,
                "DefaultEnvironment" : defaultEnvironment(containerOccurrence, contextLinks, baselineLinks),
                "Environment" :
                    {
                        "APP_RUN_MODE" : getContainerMode(container),
                        "AWS_REGION" : getRegion(),
                        "AWS_DEFAULT_REGION" : getRegion()
                    },
                "Links" : contextLinks,
                "BaselineLinks" : baselineLinks,
                "DefaultCoreVariables" : true,
                "DefaultEnvironmentVariables" : true,
                "DefaultBaselineVariables" : true,
                "DefaultLinkVariables" : true,
                "Policy" : standardPolicies(task, baselineComponentIds),
                "Privileged" : container.Privileged,
                "LogMetrics" : container.LogMetrics,
                "Alerts" : container.Alerts,
                "Container" : container,
                "InitProcess" : container.InitProcess
            } +
            attributeIfContent("LogGroup", containerLogGroup) +
            attributeIfContent("ImageVersion", container.Version) +
            attributeIfContent("Cpu", container.Cpu) +
            attributeIfContent("Gpu", container.Gpu) +
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
            attributeIfContent("PortMappings", containerPortMappings) +
            attributeIfContent("IngressRules", ingressRules) +
            attributeIfContent("InboundPorts", inboundPorts) +
            attributeIfContent("RunCapabilities", container.RunCapabilities) +
            attributeIfContent("ContainerNetworkLinks", container.ContainerNetworkLinks) +
            attributeIfContent("PlacementConstraints", container.PlacementConstraints![] ) +
            attributeIfContent("Ulimits", container.Ulimits )
        ]

        [#if container.Image.Source == "containerregistry" ]
            [#local _context += { "Image" : container.Image["Source:containerregistry"].Image }]
            [@debug message="SourceImage" context=container.Image["Source:containerregistry"].Image enabled=true /]
        [/#if]

        [#local linkIngressRules = [] ]
        [#list _context.Links as linkId,linkTarget]
            [#local linkTargetCore = linkTarget.Core ]
            [#local linkTargetConfiguration = linkTarget.Configuration ]
            [#local linkTargetResources = linkTarget.State.Resources ]
            [#local linkTargetAttributes = linkTarget.State.Attributes ]
            [#local linkTargetRoles = linkTarget.State.Roles ]

            [#if (linkTargetRoles.Outbound["networkacl"]!{})?has_content ]
                [#local egressRules += [ linkTargetRoles.Outbound["networkacl"] ]]
            [/#if]

            [#if linkTarget.Direction?lower_case == "Inbound" && linkTarget.Role == "networkacl" ]
                [#local linkIngressRules += [  mergeObjects( linkTargetRoles.Inbound["networkacl"],  { "Ports" : inboundPorts } ) ] ]]
            [/#if]

            [#switch linkTargetCore.Type]
                [#case DATAVOLUME_COMPONENT_TYPE]

                    [#local dataVolumeEngine = linkTargetAttributes["ENGINE"] ]

                    [#if ! ( ecs.Configuration.Solution.VolumeDrivers?seq_contains(dataVolumeEngine)) ]
                            [@fatal
                                message="Volume driver for this data volume not configured for ECS Cluster"
                                context=ecs.Configuration.Solution.VolumeDrivers
                                detail=ecs /]
                    [/#if]

                    [#local _context +=
                        {
                            "DataVolumes" :
                                (_context.DataVolumes!{}) +
                                {
                                    linkId : {
                                        "Name" : linkTargetAttributes["VOLUME_NAME"],
                                        "Engine" : linkTargetAttributes["ENGINE"]
                                    }
                                }
                        }]
                    [#break]
                [#case FILESHARE_COMPONENT_TYPE]
                [#case FILESHARE_MOUNT_COMPONENT_TYPE]
                    [#local _context +=
                        {
                            "DataVolumes" :
                                (_context.DataVolumes!{}) +
                                {
                                    linkId : {
                                        "Name" : formatName("efs", linkTargetAttributes["EFS"], linkTargetAttributes["ACCESS_POINT_ID"]!""),
                                        "Engine" : "efs",
                                        "EFS" : {
                                            "FileSystemId" : linkTargetAttributes["EFS"]
                                        } +
                                        attributeIfContent(
                                            "AccessPointId",
                                            (linkTargetAttributes["ACCESS_POINT_ID"]!"")
                                        )
                                    }
                                }
                        }

                    ]
                    [#break]
                [#case SECRETSTORE_SECRET_COMPONENT_TYPE ]
                    [#local _context = mergeObjects(
                        _context,
                        {
                            "Secrets" : {
                                linkId : {
                                    "Provider" : linkTargetAttributes["ENGINE"],
                                    "Ref" : linkTargetResources["secret"].Id,
                                    "EncryptionKeyId" : linkTargetResources["secret"].cmkKeyId
                                }
                            }
                        })]
                    [#break]

                [#case DB_COMPONENT_TYPE]
                    [#if ((linkTargetAttributes["SECRET_ARN"])!"")?has_content ]
                        [#local _context = mergeObjects(
                            _context,
                            {
                                "Secrets" : {
                                    linkId : {
                                        "Provider" : linkTargetResources["rootCredentials"]["secret"].Provider,
                                        "Ref" : linkTargetResources["rootCredentials"]["secret"].Id,
                                        "EncryptionKeyId" : linkTargetResources["rootCredentials"]["secret"].cmkKeyId
                                    }
                                }
                            }
                        )]
                    [/#if]
                    [#break]
            [/#switch]
        [/#list]

        [#-- Add link based sec rules --]
        [#local _context += { "EgressRules" : egressRules }]
        [#local _context += { "LinkIngressRules" : linkIngressRules }]

        [#-- Add in extension specifics including override of defaults --]
        [#-- Extensions are based on occurrences so we need to create a fake occurrence --]
        [#local containerOccurrence = mergeObjects(
            containerOccurrence,
            {
                "Core" : {
                    "Component" : containerDetails
                },
                "Configuration" : {
                    "Solution" : container
                }
            }
        )]
        [#local _context = invokeExtensions(task, _context, containerOccurrence, [ container.Extensions ] )]
        [#local _context += containerDetails ]
        [#local _context += getFinalEnvironment(task, _context) ]

        [#-- validate fargate requirements from container context --]
        [#if solution.Engine == "fargate" ]
            [#local fargateInvalidConfig = false ]
            [#local fargateInvalidConfigMessage = [] ]

            [#if !( [ 256, 512, 1024, 2048, 4096 ]?seq_contains(_context.Cpu) )  ]
                [#local fargateInvalidConfig = true ]
                [#local fargateInvalidConfigMessage += [ "CPU quota is not valid ( must be divisible by 256 )" ] ]
            [/#if]

            [#if !( _context.MaximumMemory?has_content )  ]
                [#local fargateInvalidConfig = true ]
                [#local fargateInvalidConfigMessage += [ "Maximum memory must be assigned" ]]
            [/#if]

            [#if (_context.Privileged )]
                [#local fargateInvalidConfig = true ]
                [#local fargateInvalidConfigMessage += [ "Cannot run in priviledged mode" ] ]
            [/#if]

            [#if _context.ContainerNetworkLinks!{}?has_content ]
                [#local fargateInvalidConfig = true ]
                [#local fargateInvalidConfigMessage += [ "Cannot use Network Links" ] ]
            [/#if]

            [#if (_context.Hosts!{})?has_content ]
                [#local fargateInvalidConfig = true ]
                [#local fargateInvalidConfigMessage += [ "Cannot add host entries" ] ]
            [/#if]

            [#list _context.Volumes!{} as name,volume ]
                [#if volume.hostPath?has_content || volume.PersistVolume || ( volume.Driver != "local" && volume.Driver != "efs" ) ]
                    [#local fargateInvalidConfig = true ]
                    [#local fargateInvalidConfigMessage += [ "Can only use the local or efs driver and cannot reference host - volume ${name}" ] ]
                [/#if]
            [/#list]

            [#if fargateInvalidConfig ]
                [@fatal
                    message="Invalid Fargate configuration"
                    context=
                        {
                            "Description" : "Fargate containers only support the awsvpc network mode",
                            "ValidationErrors" : fargateInvalidConfigMessage
                        }
                    detail=solution
                /]
            [/#if]
        [/#if]

        [#local containers += [_context] ]
    [/#list]

    [#return containers]
[/#function]
