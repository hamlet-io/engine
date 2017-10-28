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

[#macro Attributes name="" image="" essential=true]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Essential" : essential
            } +
            attributeIfContent("Name", name) +
            attributeIfContent("Image", image, formatRelativePath(getRegistryEndPoint("docker"), image))
        ]
    [/#if]
[/#macro]

[#macro Link name link attribute="Url"]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Environment" :
                  (currentContainer.Environment!{}) +
                  {
                      name  : (currentContainer.Links[link][attribute])!""
                  }
            }
        ]
    [/#if]
[/#macro]

[#macro Variable name value]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Environment" : (currentContainer.Environment!{}) + { name : value }
            }
        ]
    [/#if]
[/#macro]

[#macro Variables variables={}]
    [#if ((containerListMode!"") == "model") && variables?is_hash]
        [#assign currentContainer +=
            {
                "Environment" : (currentContainer.Environment!{}) + variables
            }
        ]
    [/#if]
[/#macro]

[#macro Host name value]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Hosts" : (currentContainer.Hosts!{}) + { name : value }
            }
        ]
    [/#if]
[/#macro]

[#macro Hosts hosts]
    [#if ((containerListMode!"") == "model") && hosts?is_hash]
        [#assign currentContainer +=
            {
                "Hosts" : (currentContainer.Hosts!{}) + hosts
            }
        ]
    [/#if]
[/#macro]

[#macro Volume name containerPath hostPath="" readonly=false]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Volumes" :
                    (currentContainer.Volumes!{}) + 
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
        [#assign currentContainer +=
            {
                "Volumes" : (currentContainer.Volumes!{}) + volumes
            }
        ]
    [/#if]
[/#macro]

[#macro Policy statements]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Policy" : (currentContainer.Policy![]) + asArray(statements)
            }
        ]
    [/#if]
[/#macro]

[#function standardEnvironment tier component occurrence mode=""]
    [#return
        {
            "TEMPLATE_TIMESTAMP" : .now?iso_utc,
            "PRODUCT" : productName,
            "ENVIRONMENT" : environmentName,
            "SEGMENT" : segmentName,
            "TIER" : getTierName(tier),
            "COMPONENT" : getComponentName(component),
            "COMPONENT_INSTANCE" : occurrence.InstanceName,
            "COMPONENT_VERSION" : occurrence.VersionName,
            "REQUEST_REFERENCE" : requestReference,
            "CONFIGURATION_REFERENCE" : configurationReference,
            "APPDATA_BUCKET" : dataBucket,
            "APPDATA_PREFIX" : getAppDataFilePrefix(),
            "OPSDATA_BUCKET" : operationsBucket,
            "APPSETTINGS_PREFIX" : getAppSettingsFilePrefix(),
            "CREDENTIALS_PREFIX" : getCredentialsFilePrefix()
        } +
        attributeIfContent("APP_RUN_MODE", mode) +
        attributeIfContent("BUILD_REFERENCE", buildCommit!"") +
        attributeIfContent("APP_REFERENCE", appReference!"")
    ]
[/#function]

[#function getTaskContainers tier component task]
    
    [#local containers = [] ]

    [#list (task.Containers!{})?values as container]
        [#if container?is_hash]

            [#local portMappings = [] ]
            [#list (container.Ports!{})?values as port]
                [#if port?is_hash]
                    [#local targetLoadBalancer = {} ]
                    [#local targetTierId = (port.LB.Tier)!port.ELB?has_content?then("elb", "") ]
                    [#local targetComponentId = port.LB.Component!port.ELB?has_content?then(port.ELB, "") ]
                    [#local targetGroup = ""]
                    [#local targetPath = (port.LB.Path)!""]
                    [#local targetType = port.ELB?has_content?then("elb", "alb")]
                    
                    [#if targetTierId?has_content && targetComponentId?has_content]
                        [#-- Work out which occurrence to use --]
                        [#local targetComponent =
                            getComponent(
                                targetTierId,
                                targetComponentId,
                                targetType)]
                        [#local instanceAndVersionMatch = {}]
                        [#local instanceMatch = {}]
                        [#if targetComponent?has_content]
                            [#list getOccurrences(targetComponent) as targetOccurrence]
                                [#if task.InstanceId == targetOccurrence.InstanceId]
                                    [#if task.VersionId == targetOccurrence.VersionId]
                                        [#local instanceAndVersionMatch = targetOccurrence]
                                    [#else]
                                        [#if (task.VersionId?has_content) &&
                                                (!(targetOccurrence.VersionId?has_content))]                                              
                                            [#local instanceMatch = targetOccurrence]
                                        [/#if]
                                    [/#if]
                                [/#if]
                            [/#list]
                        [/#if]
                        [#if instanceAndVersionMatch?has_content]
                            [#local targetLoadBalancer = instanceAndVersionMatch]
                            [#if (targetType == "alb") && (!(targetGroup?has_content))]
                                [#local targetGroup = "default"]
                            [/#if]
                        [#else]
                            [#if instanceMatch?has_content && (targetType == "alb")]
                                [#local targetLoadBalancer = instanceMatch]
                                [#local targetGroup = task.VersionId]
                                [#local targetPath =
                                    "/" + task.VersionId + 
                                    (port.LB.Path)?has_content?then(
                                        port.LB.Path,
                                        "/*"
                                    )
                                ]
                            [/#if]
                        [/#if]
                            
                        [#local targetPort =
                            (port.LB.Port)?has_content?then(
                                port.LB.Port,
                                (port.LB.PortMapping)?has_content?then(
                                    portMappings[lb.PortMapping].Source,
                                    port.Id
                                )
                            )]
                    [/#if]

                    [#local portMappings +=
                        [
                            {
                                "ContainerPort" :
                                    port.Container?has_content?then(
                                        port.Container,
                                        port.Id
                                    ),
                                "HostPort" : port.Id,
                                "DynamicHostPort" : port.DynamicHostPort!false
                            } +
                            valueIfContent(
                                {
                                    "LoadBalancer" :
                                        {
                                            "Tier" : targetTierId,
                                            "Component" : targetComponentId,
                                            "Instance" : targetLoadBalancer.InstanceId,
                                            "Version" : targetLoadBalancer.VersionId
                                        } +
                                        valueIfContent(
                                                {
                                                    "TargetGroup" : targetGroup,
                                                    "Port" : targetPort
                                                } +
                                                attributeIfContent("Priority",(port.LB.Priority)!"") +
                                                attributeIfContent("Path", targetPath),
                                            targetGroup
                                        )
                                },
                                targetLoadBalancer
                            )
                        ]
                    ]
                [/#if]
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

            [#assign currentContainer = 
                {
                    "Id" : getContainerId(container),
                    "Name" : getContainerName(container),
                    "Essential" : true,
                    "Image" :
                        formatRelativePath(
                            getRegistryEndPoint("docker"),
                            productName,
                            formatName(
                                buildDeploymentUnit,
                                buildCommit
                            )
                        ),
                    "MemoryReservation" : container.Memory,
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
                        }
                } +
                attributeIfContent("Version", container.Version!"") +
                attributeIfContent("Cpu", container.Cpu!"") +
                attributeIfContent("MaximumMemory", container.MaximumMemory!"") +
                attributeIfContent("PortMappings", portMappings)
            ]

            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(task, container)]
            [#include containerList]
            
            [#local containers += [currentContainer] ]
        [/#if]
    [/#list]
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

