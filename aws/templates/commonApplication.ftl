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
            name?has_content?then(
                {
                    "Name" : name
                },
                {}
            ) + 
            image?has_content?then(
                {    
                    "Image" : formatRelativePath(getRegistryEndPoint("docker"), image)
                },
                {}
            )
        ]
    [/#if]
[/#macro]

[#macro Variable name value]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer += {"Environment" : { name : value }} ]
    [/#if]
[/#macro]

[#macro Variables variables={}]
    [#if ((containerListMode!"") == "model") && variables?is_hash]
        [#assign currentContainer += {"Environment" : variables} ]
    [/#if]
[/#macro]

[#macro Host name value]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer += {"Hosts" : { name : value }} ]
    [/#if]
[/#macro]

[#macro Hosts hosts]
    [#if ((containerListMode!"") == "model") && hosts?is_hash]
        [#assign currentContainer += { "Hosts" : hosts } ]
    [/#if]
[/#macro]

[#macro Volume name containerPath hostPath="" readonly=false]
    [#if (containerListMode!"") == "model"]
        [#assign currentContainer +=
            {
                "Volumes" : {
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
        [#assign currentContainer += { "Volumes" : volumes } ]
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

[#function getTaskContainers tier component task]
    
    [#local containers = {} ]

    [#list (task.Containers!{})?values as container]
        [#if container?is_hash]

            [#local portMappings = [] ]
            [#local loadBalancers = [] ]
            [#list (container.Ports!{})?values as port]
                [#if port?is_hash]
                    [#local portMappings +=
                        {
                            "ContainerPort" :
                                port.Container?then(
                                    ports[port.Container].Port,
                                    ports[port.Id].Port
                                ),
                            "HostPort" :
                                port.DynamicHostPort!false)?then(
                                    0,
                                    ports[port.Id].Port
                                )
                        }
                    ]
                [/#if]
            [/#list]
            
            [#local logDriver = 
                (container.LogDriver)!
                (appSettingsObject.Docker.LogDriver)!
                (
                    (appSettingsObject.Docker.LocalLogging)!false) ||
                    (container.LocalLogging!false)
                )?then(
                    "json-file",
                    "awslogs"
                )]
                
            [#local logOptions = 
                container.LogDriver?switch(
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
                            getReference(formatComponentLogGroupId(tier component)),
                        "awslogs-region": regionId,
                        "awslogs-stream-prefix": formatName(task)
                    },
                    {}
                )]

            [#assign currentContainer = 
                {
                    "Id" : getContainerId(container),
                    "Name" : getContainerName(container),
                    "Image" :
                        formatRelativePath(
                            getRegistryEndPoint("docker"),
                            productName,
                            buildDeploymentUnit,
                            buildCommit
                        ),
                    "MemoryReservation" : container.Memory,
                    "LogDriver" : logDriver,
                    "LogOptions" :logOptions,
                    "Environment" :
                        {
                            "TEMPLATE_TIMESTAMP" .now?iso_utc,
                            "AWS_REGION": regionId,
                            "ENVIRONMENT" : environmentName,
                            "REQUEST_REFERENCE" : requestReference,
                            "CONFIGURATION_REFERENCE" : configurationReference,
                            "APPDATA_BUCKET" : dataBucket,
                            "APPDATA_PREFIX" : getAppDataFilePrefix(),
                            "OPSDATA_BUCKET" : operationsBucket,
                            "APPSETTINGS_PREFIX" : getAppSettingsFilePrefix(),
                            "CREDENTIALS_PREFIX" : getCredentialsFilePrefix(),
                            "APP_RUN_MODE" : getContainerMode(container),
                        } +
                        buildCommit?has_content?then(
                            {
                                "BUILD_REFERENCE" : buildCommit
                            },
                            {}
                        ) +
                        appReference?has_content?then(
                            {
                                "APP_REFERENCE" : appReference
                            }
                } +
                container.Version?has_content?then(
                    {
                        "Version" : container.Version
                    },
                    {}
                ) +
                container.Cpu?has_content?then(
                    {
                        "Cpu" : container.Cpu
                    },
                    {}
                ) +
                container.MaximumMemory?has_content?then(
                    {
                        "MaximumMemory" : container.MaximumMemory
                    },
                    {}
                ) +
                portMappings?has_content?then(
                    {
                        "PortMappings" : portMappings
                    },
                    {}
                )
            ]

            [#-- Add in container specifics including override of defaults --]
            [#assign containerListMode = "model"]
            [#assign containerId = formatContainerFragmentId(task, container)]
            [#include containerList]
            
            [#local containers += { currentContainer.Id : currentContainer }]
        [/#if]
    [/#list]
    [#return containers]
[/#function]
    
[#macro createTaskRole]
    [#assign taskId = formatECSTaskId(tier component task)]
    [#assign taskLogGroupId = formatComponentLogGroupId(tier component)]
    
    [#-- Set up context for processing the list of containers --]
    [#assign containerListTarget = "docker"]
    [#assign containerListRole = formatDependentRoleId(taskId)]

    [#-- Create a role under which the task will run and attach required policies --]
    [#if isPartOfCurrentDeploymentUnit(containerListRole)]
        [@createRole 
            mode=applicationListMode
            id=containerListRole
            trustedServices=["ecs-tasks.amazonaws.com"]
        /]
        
        [#switch applicationListMode]
            [#case "definition"]
                [#assign containerListMode = "policy"]
                [#list task.Containers?values as container]
                    [#if container?is_hash]
                        [#assign containerId = formatContainerId(
                                                task,
                                                container)]
                        [#assign containerName = formatContainerName(
                                                   tier,
                                                   component,
                                                   task,
                                                   container)]
                        [#assign containerRunMode = getContainerMode(container)]
                        [#assign containerListPolicyId = formatDependentPolicyId(
                                                            taskId,
                                                            getContainerId(container))]
                        [#assign containerListPolicyName = formatContainerPolicyName(
                                                            tier,
                                                            component,
                                                            task,
                                                            container)]
                        [#include containerList]
                    [/#if]
                [/#list]
                [#break]
        [/#switch]
    [#else]
        [#-- Needed to ensure policy macro works in non-policy list modes --]
        [#assign containerListPolicyId = ""]
        [#assign containerListPolicyName = ""]
    [/#if]

    [#if !iamOnly]
        [#switch applicationListMode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                "${taskId}" : {
                    "Type" : "AWS::ECS::TaskDefinition",
                    "Properties" : {
                        "ContainerDefinitions" : [
                            [#assign containerCount = 0]
                            [#list task.Containers?values as container]
                                [#if container?is_hash]
                                    [#assign dockerTag = ""]
                                    [#if container.Version??]
                                        [#assign dockerTag = ":" + container.Version]
                                    [/#if]
                                    formatRelativePath(
                                        getRegistryEndPoint("docker"),
                                        image?has_content?then(
                                            image,
                                            formatRelativePath(
                                                productName,
                                                buildDeploymentUnit,
                                                buildCommit
                                            )
                                        )
                                    )
                                    [#if containerCount > 0],[/#if]
                                    {
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerName = formatContainerName(
                                                                   tier,
                                                                   component,
                                                                   task,
                                                                   container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#assign containerListMode = "definition"]
                                        [#include containerList]
                                        [#assign containerListMode = "environmentCount"]
                                        [#assign environmentCount = 0]
                                        [#include containerList]
                                        [#if environmentCount > 0]
                                            "Environment" : [
                                                [#assign environmentCount = 0]
                                                [#assign containerListMode = "environment"]
                                                [#include containerList]
                                            ],
                                        [/#if]
                                        [#assign containerListMode = "mountPointCount"]
                                        [#assign mountPointCount = 0]
                                        [#include containerList]
                                        [#if mountPointCount > 0]
                                            "MountPoints" : [
                                                [#assign mountPointCount = 0]
                                                [#assign containerListMode = "mountPoints"]
                                                [#include containerList]
                                            ],
                                        [/#if]
                                        "MemoryReservation" : ${container.Memory?c},
                                        [#if container.MaximumMemory?has_content]
                                            "Memory" : ${container.MaximumMemory?c},
                                        [/#if]
                                        "Cpu" : ${container.Cpu?c},                            
                                        [#if container.Ports??]
                                            "PortMappings" : [
                                                [#assign portCount = 0]
                                                [#list container.Ports?values as port]
                                                    [#if port?is_hash]
                                                        [#if portCount > 0],[/#if]
                                                        {
                                                            [#if port.Container??]
                                                                "ContainerPort" : ${ports[port.Container].Port?c},
                                                            [#else]
                                                                "ContainerPort" : ${ports[port.Id].Port?c},
                                                            [/#if]
                                                            [#if port.DynamicHostPort?? && port.DynamicHostPort]
                                                                "HostPort" : 0
                                                            [#else]
                                                                "HostPort" : ${ports[port.Id].Port?c}
                                                            [/#if]
                                                        }
                                                        [#assign portCount += 1]
                                                    [/#if]
                                                [/#list]
                                            ],
                                        [/#if]
                                        "LogConfiguration" : {
                                            [#assign logDriver =
                                                (container.LogDriver)!
                                                (appSettingsObject.Docker.LogDriver)!
                                                (
                                                    (   (appSettingsObject.Docker.LocalLogging)?? && 
                                                            appSettingsObject.Docker.LocalLogging
                                                        ) || 
                                                        (container.LocalLogging?? && container.LocalLogging)
                                                    )?then(
                                                        "json-file",
                                                        "awslogs"
                                                )
                                            ]
                                            "LogDriver": "${logDriver}"
                                            [#switch logDriver]
                                                [#case "fluentd"]
                                                        ,"Options" : { 
                                                            "tag" : "docker.${productId}.${segmentId}.${tier.Id}.${component.Id}.${container.Id}"
                                                        }
                                                    [#break]
                                                [#case "awslogs"]
                                                        ,"Options" : { 
                                                            "awslogs-group": "${getKey(taskLogGroupId)}",
                                                            "awslogs-region": "${regionId}",
                                                            "awslogs-stream-prefix": "${formatName(task)}"
                                                        }
                                                    [#break]
                                            [/#switch]
                                        }
                                    }
                                    [#assign containerCount += 1]
                                [/#if]
                            [/#list]
                        ]
                        [#assign containerListMode = "volumeCount"]
                        [#assign volumeCount = 0]
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        task,
                                                        container)]
                                [#assign containerRunMode = getContainerMode(container)]
                                [#include containerList]
                            [/#if]
                        [/#list]
                        [#if volumeCount > 0]
                            ,"Volumes" : [
                                [#assign containerListMode = "volumes"]
                                [#assign volumeCount = 0]
                                [#list task.Containers?values as container]
                                    [#if container?is_hash]
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#include containerList]
                                    [/#if]
                                [/#list]
                            ]
                        [/#if]
                        ,"TaskRoleArn" : [@createArnReference containerListRole /]
                    }
                    [#if isPartOfCurrentDeploymentUnit(containerListRole)]
                        [#-- Check if policies required for the task role --]
                        [#assign containerListMode = "policyCount"]
                        [#assign policyCount = 0]
                        [#assign containerListPolicyId = ""]
                        [#assign containerListPolicyName = ""]
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        task,
                                                        container)]
                                [#assign containerRunMode = getContainerMode(container)]
                                [#include containerList]
                            [/#if]
                        [/#list]

                        [#if (policyCount > 0)]
                            ,"DependsOn" : [
                                [#-- Generate the list of policies in this template --]
                                [#-- They need to exist before the task can start --]
                                [#assign containerListMode = "policyList"]
                                [#assign policyCount = 0]
                                [#assign containerListPolicyName = ""]
                                [#list task.Containers?values as container]
                                    [#if container?is_hash]
                                        [#assign containerListPolicyId = formatDependentPolicyId(
                                                                            taskId,
                                                                            getContainerId(container))]
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#include containerList]
                                    [/#if]
                                [/#list]
                            ]
                        [/#if]
                    [/#if]
                }
                [@resourcesCreated /]
                [#break]
    
                [#case "outputs"]
                    [@output taskId /]
                [#break]
    
        [/#switch]
    [/#if]
[/#macro]

[#macro createTask tier component task iamOnly]
    [#assign taskId = formatECSTaskId(tier component task)]
    [#assign taskLogGroupId = formatComponentLogGroupId(tier component)]
    
    [#-- Set up context for processing the list of containers --]
    [#assign containerListTarget = "docker"]
    [#assign containerListRole = formatDependentRoleId(taskId)]

    [#-- Create a role under which the task will run and attach required policies --]
    [#if isPartOfCurrentDeploymentUnit(containerListRole)]
        [@createRole
            mode=applicationListMode
            id=containerListRole
            trustedServices=["ecs-tasks.amazonaws.com"]
        /]
        
        [#switch applicationListMode]
            [#case "definition"]
                [#assign containerListMode = "policy"]
                [#list task.Containers?values as container]
                    [#if container?is_hash]
                        [#assign containerId = formatContainerId(
                                                task,
                                                container)]
                        [#assign containerName = formatContainerName(
                                                   tier,
                                                   component,
                                                   task,
                                                   container)]
                        [#assign containerRunMode = getContainerMode(container)]
                        [#assign containerListPolicyId = formatDependentPolicyId(
                                                            taskId,
                                                            getContainerId(container))]
                        [#assign containerListPolicyName = formatContainerPolicyName(
                                                            tier,
                                                            component,
                                                            task,
                                                            container)]
                        [#include containerList]
                    [/#if]
                [/#list]
                [#break]
        [/#switch]
    [#else]
        [#-- Needed to ensure policy macro works in non-policy list modes --]
        [#assign containerListPolicyId = ""]
        [#assign containerListPolicyName = ""]
    [/#if]

    [#if !iamOnly]
        [#switch applicationListMode]
            [#case "definition"]
                [@checkIfResourcesCreated /]
                "${taskId}" : {
                    "Type" : "AWS::ECS::TaskDefinition",
                    "Properties" : {
                        "ContainerDefinitions" : [
                            [#assign containerCount = 0]
                            [#list task.Containers?values as container]
                                [#if container?is_hash]
                                    [#assign dockerTag = ""]
                                    [#if container.Version??]
                                        [#assign dockerTag = ":" + container.Version]
                                    [/#if]
                                    formatRelativePath(
                                        getRegistryEndPoint("docker"),
                                        image?has_content?then(
                                            image,
                                            formatRelativePath(
                                                productName,
                                                buildDeploymentUnit,
                                                buildCommit
                                            )
                                        )
                                    )
                                    [#if containerCount > 0],[/#if]
                                    {
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerName = formatContainerName(
                                                                   tier,
                                                                   component,
                                                                   task,
                                                                   container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#assign containerListMode = "definition"]
                                        [#include containerList]
                                        [#assign containerListMode = "environmentCount"]
                                        [#assign environmentCount = 0]
                                        [#include containerList]
                                        [#if environmentCount > 0]
                                            "Environment" : [
                                                [#assign environmentCount = 0]
                                                [#assign containerListMode = "environment"]
                                                [#include containerList]
                                            ],
                                        [/#if]
                                        [#assign containerListMode = "mountPointCount"]
                                        [#assign mountPointCount = 0]
                                        [#include containerList]
                                        [#if mountPointCount > 0]
                                            "MountPoints" : [
                                                [#assign mountPointCount = 0]
                                                [#assign containerListMode = "mountPoints"]
                                                [#include containerList]
                                            ],
                                        [/#if]
                                        "MemoryReservation" : ${container.Memory?c},
                                        [#if container.MaximumMemory?has_content]
                                            "Memory" : ${container.MaximumMemory?c},
                                        [/#if]
                                        "Cpu" : ${container.Cpu?c},                            
                                        [#if container.Ports??]
                                            "PortMappings" : [
                                                [#assign portCount = 0]
                                                [#list container.Ports?values as port]
                                                    [#if port?is_hash]
                                                        [#if portCount > 0],[/#if]
                                                        {
                                                            [#if port.Container??]
                                                                "ContainerPort" : ${ports[port.Container].Port?c},
                                                            [#else]
                                                                "ContainerPort" : ${ports[port.Id].Port?c},
                                                            [/#if]
                                                            [#if port.DynamicHostPort?? && port.DynamicHostPort]
                                                                "HostPort" : 0
                                                            [#else]
                                                                "HostPort" : ${ports[port.Id].Port?c}
                                                            [/#if]
                                                        }
                                                        [#assign portCount += 1]
                                                    [/#if]
                                                [/#list]
                                            ],
                                        [/#if]
                                        "LogConfiguration" : {
                                            [#assign logDriver =
                                                (container.LogDriver)!
                                                (appSettingsObject.Docker.LogDriver)!
                                                (
                                                    (   (appSettingsObject.Docker.LocalLogging)?? && 
                                                            appSettingsObject.Docker.LocalLogging
                                                        ) || 
                                                        (container.LocalLogging?? && container.LocalLogging)
                                                    )?then(
                                                        "json-file",
                                                        "awslogs"
                                                )
                                            ]
                                            "LogDriver": "${logDriver}"
                                            [#switch logDriver]
                                                [#case "fluentd"]
                                                        ,"Options" : { 
                                                            "tag" : "docker.${productId}.${segmentId}.${tier.Id}.${component.Id}.${container.Id}"
                                                        }
                                                    [#break]
                                                [#case "awslogs"]
                                                        ,"Options" : { 
                                                            "awslogs-group": "${getKey(taskLogGroupId)}",
                                                            "awslogs-region": "${regionId}",
                                                            "awslogs-stream-prefix": "${formatName(task)}"
                                                        }
                                                    [#break]
                                            [/#switch]
                                        }
                                    }
                                    [#assign containerCount += 1]
                                [/#if]
                            [/#list]
                        ]
                        [#assign containerListMode = "volumeCount"]
                        [#assign volumeCount = 0]
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        task,
                                                        container)]
                                [#assign containerRunMode = getContainerMode(container)]
                                [#include containerList]
                            [/#if]
                        [/#list]
                        [#if volumeCount > 0]
                            ,"Volumes" : [
                                [#assign containerListMode = "volumes"]
                                [#assign volumeCount = 0]
                                [#list task.Containers?values as container]
                                    [#if container?is_hash]
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#include containerList]
                                    [/#if]
                                [/#list]
                            ]
                        [/#if]
                        ,"TaskRoleArn" : [@createArnReference containerListRole /]
                    }
                    [#if isPartOfCurrentDeploymentUnit(containerListRole)]
                        [#-- Check if policies required for the task role --]
                        [#assign containerListMode = "policyCount"]
                        [#assign policyCount = 0]
                        [#assign containerListPolicyId = ""]
                        [#assign containerListPolicyName = ""]
                        [#list task.Containers?values as container]
                            [#if container?is_hash]
                                [#assign containerId = formatContainerId(
                                                        task,
                                                        container)]
                                [#assign containerRunMode = getContainerMode(container)]
                                [#include containerList]
                            [/#if]
                        [/#list]

                        [#if (policyCount > 0)]
                            ,"DependsOn" : [
                                [#-- Generate the list of policies in this template --]
                                [#-- They need to exist before the task can start --]
                                [#assign containerListMode = "policyList"]
                                [#assign policyCount = 0]
                                [#assign containerListPolicyName = ""]
                                [#list task.Containers?values as container]
                                    [#if container?is_hash]
                                        [#assign containerListPolicyId = formatDependentPolicyId(
                                                                            taskId,
                                                                            getContainerId(container))]
                                        [#assign containerId = formatContainerId(
                                                                task,
                                                                container)]
                                        [#assign containerRunMode = getContainerMode(container)]
                                        [#include containerList]
                                    [/#if]
                                [/#list]
                            ]
                        [/#if]
                    [/#if]
                }
                [@resourcesCreated /]
                [#break]
    
                [#case "outputs"]
                    [@output taskId /]
                [#break]
    
        [/#switch]
    [/#if]
[/#macro]

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

