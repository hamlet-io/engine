[#ftl]

[#-- Functions --]

[#function getRegistryEndPoint type]
    [#return (appSettingsObject.Registries[type?lower_case].EndPoint)!(appSettingsObject[type?capitalize].Registry)!"unknown"]
[/#function]

[#function getRegistryPrefix type]
    [#return (appSettingsObject.Registries[type?lower_case].Prefix)!(appSettingsObject[type?capitalize].Prefix)!""]
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
            attributeIfContent("Image", image, formatRelativePath(getRegistryEndPoint("docker"), image)) +
            attributeIfContent("ImageVersion", version)
        ]
    [/#if]

    [#-- Ensure we don't trigger the build commit missing exception --]
    [#if image?has_content]
        [#assign buildCommit = image ]
    [/#if]
[/#macro]

[#function formatVariableName parts...]
    [#return concatenate(parts, "_")?upper_case?replace("-", "_") ]
[/#function]

[#function addVariableToContext context name value]
    [#return
        context +
        {
            "Environment" :
                (context.Environment!{}) +
                {
                    formatVariableName(name) : (value?is_hash || value?is_sequence)?then(getJSON(value, true), value)
                }
        }
    ]
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
        [#local result = addVariableToContext(result, name, "ERROR: No attributes found") ]
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

[#macro Setting name path=[] default=""]
    [@Variable
        name=name
        value=getDescendent(
                      appSettingsObject,
                      default,
                      path?has_content?then(path, name)) /]
[/#macro]

[#macro Credential path id="" secret="" idAttribute="Username" secretAttribute="Password"]
  [#if id?has_content]
    [@Variable
        name=id
        value=getDescendent(
                  credentialsObject,
                  "ERROR: Missing credential id",
                  path?is_string?then(path?split("."), path) + [idAttribute]) /]
  [/#if]
  [#if secret?has_content]
    [@Variable
        name=secret
        value=getDescendent(
                  credentialsObject,
                  "ERROR: Missing credential secret",
                  path?is_string?then(path?split("."), path) + [secretAttribute]) /]
  [/#if]
[/#macro]

[#macro Settings settings...]
    [#list asFlattenedArray(settings) as setting]
        [#if setting?is_string]
            [@Setting
                name=setting /]
        [/#if]
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

[#function standardEnvironment tier component occurrence mode=""]
    [#local core = occurrence.Core ]
    [#return
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
            "APPDATA_BUCKET" : dataBucket,
            "APPDATA_PREFIX" : getAppDataFilePrefix(),
            "OPSDATA_BUCKET" : operationsBucket,
            "APPSETTINGS_PREFIX" : getAppSettingsFilePrefix(),
            "CREDENTIALS_PREFIX" : getCredentialsFilePrefix()
        } +
        attributeIfContent("SUBCOMPONENT", core.SubComponent.Name!"") +
        attributeIfContent("APP_RUN_MODE", mode) +
        attributeIfContent("BUILD_REFERENCE", buildCommit!"") +
        attributeIfContent("APP_REFERENCE", appReference!"") +
        attributeIfContent("APPDATA_PUBLIC_PREFIX" getAppDataPublicFilePrefix()) +
        attributeIfContent("SES_REGION", (productObject.SES.Region)!"")
    ]
[/#function]

[#function getTaskContainers task]

    [#local core = task.Core ]
    [#local configuration = task.Configuration ]

    [#local tier = core.Tier ]
    [#local component = core.Component ]

    [#local containers = [] ]

    [#list configuration.Containers?values as container]
        [#local containerPortMappings = [] ]
        [#local containerLinks = container.Links ]
        [#list container.Ports?values as port]
            [#local targetLoadBalancer = {} ]
            [#local targetTierId = (port.LB.Tier)!port.ELB ]
            [#local targetComponentId = (port.LB.Component)!port.ELB ]
            [#local targetLinkName = port.LB.LinkName ]
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
                attributeIfTrue("Version", port.LB.Version??, port.LB.Version!"") ]

            [@cfDebug listMode targetLink false /]

            [#if targetTierId?has_content && targetComponentId?has_content]
                [#local targetLoadBalancer = getLinkTarget(task, targetLink) ]

                [@cfDebug listMode targetLoadBalancer false /]

                [#if targetLoadBalancer?has_content ]

                    [#local targetGroup = port.LB.TargetGroup]
                    [#local targetPath = port.LB.Path]
                    [#local targetPort = port.LB.Port]
                    [#local targetPortMapping = port.LB.PortMapping]
                    [#local targetPort =
                        contentIfContent(
                            targetPort,
                            valueIfContent(
                                (portMappings[targetPortMapping!""].Source)!"",
                                targetPortMapping!"",
                                port.Id
                            )
                        ) ]
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
                                "Tier" : targetTierId,
                                "Component" : targetComponentId,
                                "Instance" : targetLoadBalancer.Core.Instance.Id,
                                "Version" : targetLoadBalancer.Core.Version.Id
                            } +
                            valueIfContent(
                                {
                                    "TargetGroup" : targetGroup,
                                    "Port" : targetPort,
                                    "Priority" : port.LB.Priority,
                                    "Path" : targetPath
                                },
                                targetGroup
                            )
                    }
                ]
            [/#if]
            [#local containerPortMappings += [containerPortMapping] ]
        [/#list]

        [#local logDriver =
            (container.LogDriver)!
            (appSettingsObject.Docker.LogDriver)!
            (
                ((appSettingsObject.Docker.LocalLogging)!false) ||
                (container.LocalLogging!false)
            )?then(
                "json-file",
                "awslogs"
            )]

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
                "Image" :
                    formatRelativePath(
                        getRegistryEndPoint("docker"),
                        productName,
                        formatName(
                            buildDeploymentUnit,
                            buildCommit!"build_commit_missing"
                        )
                    ),
                "MemoryReservation" : container.MemoryReservation,
                "Mode" : getContainerMode(container),
                "LogDriver" : logDriver,
                "LogOptions" : logOptions,
                "Environment" :
                    standardEnvironment(
                        tier,
                        component,
                        task,
                        getContainerMode(container)) +
                    {
                        "AWS_REGION" : regionId
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

        [#-- Ensure the image has been defined --]
        [#if !buildCommit?has_content]
            [@cfException listMode "Build commit missing" /]
        [/#if]

        [#local containers += [context] ]
    [/#list]

    [@cfDebug listMode containers false /]

    [#return containers]
[/#function]

[#-- Initialisation --]

[#if buildReference?has_content]
    [#if buildReference?starts_with("{")]
        [#-- JSON format --]
        [#assign buildReferenceObject = buildReference?eval]
        [#assign buildCommit =
            buildReferenceObject.commit!buildReferenceObject.Commit!""]
        [#assign appReference =
            buildReferenceObject.tag!buildReferenceObject.Tag!""]
    [#else]
        [#-- Legacy format --]
        [#assign buildCommit = buildReference]
        [#assign appReference = ""]
        [#assign buildSeparator = buildReference?index_of(" ")]
        [#if buildSeparator != -1]
            [#assign buildCommit = buildReference[0..(buildSeparator-1)]]
            [#assign appReference = buildReference[(buildSeparator+1)..]]
        [/#if]
    [/#if]
[/#if]

