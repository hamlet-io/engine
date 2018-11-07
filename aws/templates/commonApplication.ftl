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

[#-- Fragment List Macros --]

[#macro Attributes name="" image="" version="" essential=true]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context +=
            {
                "Essential" : essential
            } +
            attributeIfContent("Name", name) +
            attributeIfContent("Image", image) +
            attributeIfContent("ImageVersion", version)
        ]
    [/#if]
[/#macro]

[#macro lambdaAttributes imageBucket="" imagePrefix="" zipFile="" ]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context += {
                "S3Bucket" : imageBucket,
                "S3Prefix" : imagePrefix,
                "ZipFile" : {
                    "Fn::Join" : [
                        "\n",
                        asArray(zipFile)
                    ]
                }
            }
        ]
    [/#if]
[/#macro]

[#function addVariableToContext context name value]
    [#return
        setDescendent(
            context,
            asSerialisableString(value),
            formatSettingName(name)
            "Environment") ]
[/#function]

[#macro Variable name value]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context = addVariableToContext(_context, name, value) ]
    [/#if]
[/#macro]

[#function getLinkResourceId link alias]
    [#return (_context.Links[link].State.Resources[alias].Id)!"" ]
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

[#function getDefaultLinkVariables links includeInbound=false]
    [#local result = {"Links" : links, "Environment": {} }]
    [#list links as name,value]
        [#if (value.Direction != "inbound") || includeInbound]
            [#local result = addLinkVariablesToContext(result, name, name, [], false) ]
        [/#if]
    [/#list]
    [#return result.Environment]
[/#function]

[#macro Link name link="" attributes=[] rawName=false ignoreIfNotDefined=false]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context =
            addLinkVariablesToContext(
                _context,
                name,
                contentIfContent(link, name),
                attributes,
                rawName,
                ignoreIfNotDefined) ]
    [/#if]
[/#macro]

[#macro DefaultLinkVariables enabled=true ]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context += { "DefaultLinkVariables" : enabled } ]
    [/#if]
[/#macro]

[#macro DefaultCoreVariables enabled=true ]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context += { "DefaultCoreVariables" : enabled } ]
    [/#if]
[/#macro]

[#macro DefaultEnvironmentVariables enabled=true ]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context += { "DefaultEnvironmentVariables" : enabled } ]
    [/#if]
[/#macro]

[#function getFragmentSettingValue key value asBoolean=false]
    [#if value?is_hash]
        [#local name = contentIfContent(value.Setting!"", key) ]

        [#if (value.IgnoreIfMissing!false) &&
            (!((_context.DefaultEnvironment[formatSettingName(name)])??)) ]
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
            _context.DefaultEnvironment[formatSettingName(name)]!
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
    [#if (fragmentListMode!"") == "model"]
        [#assign _context +=
            {
                "Hosts" : (_context.Hosts!{}) + { name : value }
            }
        ]
    [/#if]
[/#macro]

[#macro Hosts hosts]
    [#if ((fragmentListMode!"") == "model") && hosts?is_hash]
        [#assign _context +=
            {
                "Hosts" : (_context.Hosts!{}) + hosts
            }
        ]
    [/#if]
[/#macro]

[#macro WorkingDirectory workingDirectory ]
        [#if ((fragmentListMode!"") == "model")]
        [#assign _context +=
            {
                "WorkingDirectory" : workingDirectory
            }
        ]
    [/#if]
[/#macro]

[#macro Volume name containerPath hostPath="" readOnly=false]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context +=
            {
                "Volumes" :
                    (_context.Volumes!{}) +
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
    [#if ((fragmentListMode!"") == "model") && volumes?is_hash]
        [#assign _context +=
            {
                "Volumes" : (_context.Volumes!{}) + volumes
            }
        ]
    [/#if]
[/#macro]

[#macro EntryPoint entrypoint ]
    [#if ((fragmentListMode!"") == "model") ]
        [#assign _context +=
            {
                "EntryPoint" : entrypoint?is_string?then(
                    entrypoint?split(" "),
                    entrypoint
                )
            }
        ]
    [/#if]
[/#macro]

[#macro Command command ]
    [#if ((fragmentListMode!"") == "model") ]
        [#assign _context +=
            {
                "Command" : command?is_string?then(
                    [ command ],
                    command
                )
            }
        ]
    [/#if]
[/#macro]

[#macro Policy statements...]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context +=
            {
                "Policy" : (_context.Policy![]) + asFlattenedArray(statements)
            }
        ]
    [/#if]
[/#macro]

[#macro ManagedPolicy arns...]
    [#if (fragmentListMode!"") == "model"]
        [#assign _context +=
            {
                "ManagedPolicy" : (_context.ManagedPolicy![]) + asFlattenedArray(arns)
            }
        ]
    [/#if]
[/#macro]

[#-- Compute instance fragment macros --]
[#macro File path mode="644" owner="root" group="root" content=[] ]
    [#if (fragmentListMode!"") == "model"]
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
    [/#if]
[/#macro]

[#macro Directory path mode="755" owner="root" group="root" ]
    [#if (fragmentListMode!"") == "model"]
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
    [/#if]
[/#macro]

[#assign ECS_DEFAULT_MEMORY_LIMIT_MULTIPLIER=1.5 ]

[#function defaultEnvironment occurrence links]
    [#return
        occurrence.Configuration.Environment.General +
        occurrence.Configuration.Environment.Build +
        occurrence.Configuration.Environment.Sensitive +
        getDefaultLinkVariables(links, true)
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
            s3ReadPermission(operationsBucket, getSettingsFilePrefix(occurrence)) +
            s3ListPermission(operationsBucket, getSettingsFilePrefix(occurrence)),
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

[#function getFinalEnvironment occurrence context environmentSettings={}]
    [#local asFile = environmentSettings.AsFile!false]
    [#local serialisationConfig = environmentSettings.Json!{}]
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
                    asFile,
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
                    valueIfTrue(
                        getDefaultLinkVariables(context.Links),
                        context.DefaultLinkVariables
                    ) +
                    context.Environment
                )
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
                    [@cfException
                        mode=listMode
                        description="Duplicate Link Name"
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

            [#if port.IPAddressGroups?has_content]
                [#if solution.NetworkMode == "awsvpc" || !port.LB.Configured ]
                    [#list getGroupCIDRs(port.IPAddressGroups ) as cidr]
                        [#local ingressRules += [ {
                            "port" : port.DynamicHostPort?then(0,contentIfContent(
                                                                            port.Container!"",
                                                                            port.Name )),
                            "cidr" : cidr
                        }]]
                    [/#list]
                [#else]
                    [@cfException
                        mode=listMode
                        description="Port IP Address Groups not supported for port configuration"
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
                "DefaultEnvironment" : defaultEnvironment(task, contextLinks),
                "Environment" :
                    {
                        "APP_RUN_MODE" : getContainerMode(container),
                        "AWS_REGION" : regionId,
                        "AWS_DEFAULT_REGION" : regionId
                    },
                "Links" : contextLinks,
                "DefaultCoreVariables" : true,
                "DefaultEnvironmentVariables" : true,
                "DefaultLinkVariables" : true,
                "Policy" : standardPolicies(task),
                "Privileged" : container.Privileged
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

        [#-- Add in fragment specifics including override of defaults --]
        [#assign fragmentListMode = "model"]
        [#assign fragmentId = formatFragmentId(_context)]
        [#assign containerId = fragmentId]
        [#include fragmentList]

        [#assign _context += getFinalEnvironment(task, _context) ]

        [#local containers += [_context] ]
    [/#list]

    [#return containers]
[/#function]
