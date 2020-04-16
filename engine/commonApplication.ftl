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
                "COTFatal: Unknown registry of type " + type
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
    [#if (container.Mode!"")?has_content ]
        [#return container.Mode ]
    [#else]
        [#assign idParts = container?is_hash?then(
                            container.Id?split("-"),
                            container?split("-"))]
        [#return idParts[1]?has_content?then(
                    idParts[1]?upper_case,
                    "WEB")]
    [/#if]
[/#function]

[#-- Fragment List Macros --]

[#macro Attributes name="" image="" version="" essential=true]
    [#assign _context +=
        {
            "Essential" : essential
        } +
        attributeIfContent("Name", name) +
        attributeIfContent("Image", image) +
        attributeIfContent("ImageVersion", version)
    ]
[/#macro]

[#macro lambdaAttributes
        imageBucket=""
        imagePrefix=""
        zipFile=""
        codeHash=""  ]

    [#assign _context += {
            "S3Bucket" : imageBucket,
            "S3Prefix" : imagePrefix,
            "ZipFile" : {
                "Fn::Join" : [
                    "\n",
                    asArray(zipFile)
                ]
            },
            "CodeHash" : codeHash
        }
    ]
[/#macro]

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

[#macro Variable name value upperCase=true ]
    [#assign _context = addVariableToContext(_context, name, value, upperCase) ]
[/#macro]

[#function getLinkResourceId link alias]
    [#return (_context.Links[link].State.Resources[alias].Id)!"" ]
[/#function]

[#function addLinkVariablesToContext context name link attributes rawName=false ignoreIfNotDefined=false requireLinkAttributes=true ]
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
                   [#local result = addVariableToContext(result, variableName, "COTFatal: Attribute " + attribute?upper_case + " not found for link " + link) ]
                [/#if]
            [/#if]
        [/#list]
    [#else]
        [#if requireLinkAttributes ]
            [#if ignoreIfNotDefined]
                [#local result = addVariableToContext(result, name, "Ignoring link " + link) ]
            [#else]
                [#local result = addVariableToContext(result, name, "COTFatal: No attributes found for link " + link) ]
            [/#if]
        [/#if]
    [/#if]
    [#return result]
[/#function]

[#function getDefaultLinkVariables links includeInbound=false]
    [#local result = {"Links" : links, "Environment": {} }]
    [#list links as name,value]
        [#if (value.Direction != "inbound") || includeInbound]
            [#local result = addLinkVariablesToContext(result, name, name, value.IncludeInContext, false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]

[#function getDefaultBaselineVariables links ]
    [#local result = {"Links" : links, "Environment": {} }]
    [#list links as name,value]
        [#if (value.Direction != "inbound") || includeInbound]
            [#local result = addLinkVariablesToContext(result, name, name, [], false, false, false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]

[#macro Link name link="" attributes=[] rawName=false ignoreIfNotDefined=false]
    [#assign _context =
        addLinkVariablesToContext(
            _context,
            name,
            contentIfContent(link, name),
            attributes,
            rawName,
            ignoreIfNotDefined) ]

[/#macro]

[#macro DefaultLinkVariables enabled=true ]
    [#assign _context += { "DefaultLinkVariables" : enabled } ]
[/#macro]

[#macro DefaultBaselineVariables enabled=true ]
    [#assign _context += { "DefaultBaselineVariables" : enabled } ]
[/#macro]

[#macro DefaultCoreVariables enabled=true ]
    [#assign _context += { "DefaultCoreVariables" : enabled } ]
[/#macro]

[#macro DefaultEnvironmentVariables enabled=true ]
    [#assign _context += { "DefaultEnvironmentVariables" : enabled } ]
[/#macro]

[#function getFragmentSettingValue key value asBoolean=false]
    [#if value?is_hash]
        [#local name = contentIfContent(value.Setting!"", key) ]

        [#if (value.IgnoreIfMissing!false) &&
            (!((_context.DefaultEnvironment[formatSettingName(true, name)])??)) ]
                [#return valueIfTrue(false, asBoolean, "") ]
        [/#if]
    [#else]
        [#if value?is_string]
            [#local name = value]
        [#else]
            [#return valueIfTrue(true, asBoolean, "COTFatal: Value for " + key + " must be a string or hash") ]
        [/#if]
    [/#if]
    [#return
        valueIfTrue(
            true,
            asBoolean,
            _context.DefaultEnvironment[formatSettingName(true, name)]!
                "COTFatal: Variable " + name + " not found"
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

[#macro ContextSetting name value ]
    [#assign _context =
                mergeObjects(
                    _context,
                    {
                        "ContextSettings" : {
                            name : value
                        }
                    }
                )]
[/#macro]

[#macro Host name value]
    [#assign _context +=
        {
            "Hosts" : (_context.Hosts!{}) + { name : value }
        }
    ]
[/#macro]

[#macro Hosts hosts]
    [#if hosts?is_hash]
        [#assign _context +=
            {
                "Hosts" : (_context.Hosts!{}) + hosts
            }
        ]
    [/#if]
[/#macro]

[#macro WorkingDirectory workingDirectory ]
    [#assign _context +=
        {
            "WorkingDirectory" : workingDirectory
        }
    ]
[/#macro]

[#macro Volume name="" containerPath="" hostPath="" readOnly=false persist=false volumeLinkId="" driverOpts={} autoProvision=false ]

    [#if volumeLinkId?has_content ]
        [#local volumeName = _context.DataVolumes[volumeLinkId].Name ]
        [#local volumeEngine = _context.DataVolumes[volumeLinkId].Engine ]
    [#else]
        [#local volumeName = name!"COTFatal: Volume Name or VolumeLinkId not provided" ]
        [#local volumeEngine = "local"]
    [/#if]

    [#switch volumeEngine ]
        [#case "ebs" ]
            [#local volumeDriver = "rexray/ebs" ]
            [#break]
        [#default]
            [#local volumeDriver = "local" ]
    [/#switch]

    [#assign _context +=
        {
            "Volumes" :
                (_context.Volumes!{}) +
                {
                    volumeName : {
                        "ContainerPath" : containerPath!"COTFatal : Container Path Not provided",
                        "HostPath" : hostPath,
                        "ReadOnly" : readOnly,
                        "PersistVolume" : persist?is_string?then(
                                            persist?boolean,
                                            persist),
                        "Driver" : volumeDriver,
                        "DriverOptions" : driverOpts,
                        "AutoProvision" : autoProvision
                    }
                }
        }
    ]
[/#macro]

[#macro Volumes volumes]
    [#if volumes?is_hash]
        [#assign _context +=
            {
                "Volumes" : (_context.Volumes!{}) + volumes
            }
        ]
    [/#if]
[/#macro]

[#macro EntryPoint entrypoint ]
    [#assign _context +=
        {
            "EntryPoint" : asArray(entrypoint)
        }
    ]
[/#macro]

[#macro Command command ]
    [#assign _context +=
        {
            "Command" : asArray(command)
        }
    ]
[/#macro]

[#macro Policy statements...]
    [#assign _context +=
        {
            "Policy" : (_context.Policy![]) + asFlattenedArray(statements)
        }
    ]
[/#macro]

[#macro ManagedPolicy arns...]
    [#assign _context +=
        {
            "ManagedPolicy" : (_context.ManagedPolicy![]) + asFlattenedArray(arns)
        }
    ]
[/#macro]

[#-- Compute instance fragment macros --]
[#macro File path mode="644" owner="root" group="root" content=[] ]
    [#assign _context +=
        {
            "Files" : (_context.Files!{}) + {
                path : {
                    "mode" : mode,
                    "owner" : owner,
                    "group" : group,
                    "content" : content
                }
            }
        }]
[/#macro]

[#macro Directory path mode="755" owner="root" group="root" ]
    [#assign _context +=
        {
            "Directories" : (_context.Directories!{}) + {
                path : {
                    "mode" : mode,
                    "owner" : owner,
                    "group" : group
                }
            }
        }]
[/#macro]

[#macro DataVolumeMount volumeLinkId deviceId mountPath ]
    [#assign _context +=
        {
            "VolumeMounts" :
                (_context.VolumeMounts!{}) +
                {
                    volumeLinkId : {
                        "DeviceId" : deviceId,
                        "MountPath" : mountPath
                    }
                }
        }]
[/#macro]

[#-- CloudFront Specific Fragment Macros --]
[#macro cfCustomHeader name value ]
    [#assign _context +=
        {
            "CustomOriginHeaders" : (_context.CustomOriginHeaders![]) + [
                getCFHTTPHeader(
                    name,
                    value )
            ]
        }]
[/#macro]

[#macro cfForwardHeaders names... ]
    [#assign _context +=
        {
            "ForwardHeaders" : (_context.ForwardHeaders![]) +
                                    asArray(names)
        }]
[/#macro]

[#assign ECS_DEFAULT_MEMORY_LIMIT_MULTIPLIER=1.5 ]

[#function defaultEnvironment occurrence links baselineLinks]
    [#return
        occurrence.Configuration.Environment.General +
        occurrence.Configuration.Environment.Build +
        occurrence.Configuration.Environment.Sensitive +
        getDefaultLinkVariables(links, true) +
        getDefaultBaselineVariables(baselineLinks)
    ]
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
            s3ListPermission(baselineIds["OpsData"], getSettingsFilePrefix(occurrence)),
            permissions.AsFile,
            []
        ) +
        valueIfTrue(
            s3AllPermission(baselineIds["AppData"], getAppDataFilePrefix(occurrence)),
            permissions.AppData,
            []
        ) +
        valueIfTrue(
            s3AllPermission(baselineIds["AppData"], getAppDataPublicFilePrefix(occurrence)),
            permissions.AppPublic && getAppDataPublicFilePrefix(occurrence)?has_content,
            []
        )
    ]
[/#function]

[#function getFinalEnvironment occurrence context environmentSettings={}]
    [#local asFile = environmentSettings.AsFile!false]
    [#local serialisationConfig = environmentSettings.Json!{}]

    [#local hasBaselineLinks = (context.BaselineLinks!{})?has_content]

    [#local operationsBucket = hasBaselineLinks?then(
                                context.BaselineLinks["OpsData"].State.Attributes["BUCKET"]!"COTFatal: asFile configured but could not find opsBucket",
                                ""
    )]

    [#local runId = commandLineOptions.Run.Id]
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
                        "SETTINGS_FILE" : ["s3:/", operationsBucket, getSettingsFilePrefix(occurrence), "config/config_" + runId + ".json"]?join("/"),
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

    [#list solution.Containers?values as container]
        [#local containerPortMappings = [] ]
        [#local containerLinks = mergeObjects( solution.Links, container.Links) ]
        [#local ingressRules = []]

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
                        "COTFatal: Logs type is awslogs but no group defined"
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

        [#assign contextLinks = getLinkTargets(task, containerLinks) ]
        [#assign _context =
            {
                "Id" : getContainerId(container),
                "Name" : getContainerName(container),
                "Instance" : core.Instance.Id,
                "Version" : core.Version.Id,
                "Essential" : true,
                "RegistryEndPoint" : getRegistryEndPoint("docker", task),
                "Image" :
                    formatRelativePath(
                        formatName(
                            productName,
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
                "DefaultEnvironment" : defaultEnvironment(task, contextLinks, baselineLinks),
                "Environment" :
                    {
                        "APP_RUN_MODE" : getContainerMode(container),
                        "AWS_REGION" : regionId,
                        "AWS_DEFAULT_REGION" : regionId
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
                "Alerts" : container.Alerts
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
            attributeIfContent("PortMappings", containerPortMappings) +
            attributeIfContent("IngressRules", ingressRules) +
            attributeIfContent("RunCapabilities", container.RunCapabilities) +
            attributeIfContent("ContainerNetworkLinks", container.ContainerNetworkLinks)
        ]

        [#list _context.Links as linkId,linkTarget]
            [#assign linkTargetCore = linkTarget.Core ]
            [#assign linkTargetConfiguration = linkTarget.Configuration ]
            [#assign linkTargetResources = linkTarget.State.Resources ]
            [#assign linkTargetAttributes = linkTarget.State.Attributes ]

            [#switch linkTargetCore.Type]
                [#case DATAVOLUME_COMPONENT_TYPE]

                    [#assign dataVolumeEngine = linkTargetAttributes["ENGINE"] ]

                    [#if ! ( ecs.Configuration.Solution.VolumeDrivers?seq_contains(dataVolumeEngine)) ]
                            [@fatal
                                message="Volume driver for this data volume not configured for ECS Cluster"
                                context=ecs.Configuration.Solution.VolumeDrivers
                                detail=ecs /]
                    [/#if]

                    [#assign _context +=
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
            [/#switch]
        [/#list]

        [#-- Add in fragment specifics including override of defaults --]
        [#assign fragmentId = formatFragmentId(_context)]
        [#include fragmentList]

        [#assign _context += getFinalEnvironment(task, _context) ]

        [#-- validate fargate requirements from container context --]
        [#if solution.Engine == "fargate" ]
            [#assign fargateInvalidConfig = false ]
            [#assign fargateInvalidConfigMessage = [] ]

            [#if !( [ 256, 512, 1024, 2048, 4096 ]?seq_contains(_context.Cpu) )  ]
                [#assign fargateInvalidConfig = true ]
                [#assign fargateInvalidConfigMessage += [ "CPU quota is not valid ( must be divisible by 256 )" ] ]
            [/#if]

            [#if !( _context.MaximumMemory?has_content )  ]
                [#assign fargateInvalidConfig = true ]
                [#assign fargateInvalidConfigMessage += [ "Maximum memory must be assigned" ]]
            [/#if]

            [#if (_context.Privileged )]
                [#assign fargateInvalidConfig = true ]
                [#assign fargateInvalidConfigMessage += [ "Cannot run in priviledged mode" ] ]
            [/#if]

            [#if _context.ContainerNetworkLinks!{}?has_content ]
                [#assign fargateInvalidConfig = true ]
                [#assign fargateInvalidConfigMessage += [ "Cannot use Network Links" ] ]
            [/#if]

            [#if (_context.Hosts!{})?has_content ]
                [#assign fargateInvalidConfig = true ]
                [#assign fargateInvalidConfigMessage += [ "Cannot add host entries" ] ]
            [/#if]

            [#list _context.Volumes!{} as name,volume ]
                [#if volume.hostPath?has_content || volume.PersistVolume || volume.Driver != "local" ]
                    [#assign fargateInvalidConfig = true ]
                    [#assign fargateInvalidConfigMessage += [ "Can only use the local driver and cannot reference host - volume ${name}" ] ]
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
