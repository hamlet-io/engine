[#ftl]

[#-- Functions --]

[#function getRegistryEndPoint type]
    [#return (appSettingsObject.Registries[type?lower_case].EndPoint)!(appSettingsObject[type?capitalize].Registry)!"unknown"]
[/#function]

[#function getRegistryPrefix type]
    [#return (appSettingsObject.Registries[type?lower_case].Prefix)!(appSettingsObject[type?capitalize].Prefix)!""]
[/#function]

[#function getTaskId task]
    [#local idParts = task?is_hash?then(
                        task.Id?split("-"),
                        task?split("-"))]

    [#return formatId(idParts)]
[/#function]

[#function getTaskName task]
    [#return task?is_hash?then(
                        task.Name,
                        task)]
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

[#-- Macros --]

[#macro environmentVariable name value format="docker" mode=""]
    [#-- Legacy use will not provide mode --]
    [#switch mode]
        [#case "environment"]
        [#case ""]
            [#if mode?has_content && (environmentCount > 0)],[/#if]
            [#switch format]
                [#case "docker"]
                    {
                        "Name" : "${name}",
                        "Value" : "${value}"
                    }
                    [#break]
        
                [#case "lambda"]
                [#default]
                    "${name}" : "${value}"
                    [#break]
            [/#switch]
            [#-- No break --]
        [#case "environmentCount"]
            [#if mode?has_content]
                [#assign environmentCount += 1]
            [/#if]
            [#break]
    [/#switch]
[/#macro]

[#macro standardEnvironmentVariables format="docker" mode=""]
    [@environmentVariable "TEMPLATE_TIMESTAMP" "${.now?iso_utc}" format mode /]
    [#if !mode?has_content],[/#if]
    [#-- AWS_REGION is reserved with lambda --]
    [#if format != "lambda"]
        [@environmentVariable "AWS_REGION" "${regionId}" format mode /]
        [#if !mode?has_content],[/#if]
    [/#if]
    [@environmentVariable "ENVIRONMENT" "${environmentName}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "REQUEST_REFERENCE" "${requestReference}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "CONFIGURATION_REFERENCE" "${configurationReference}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "APPDATA_BUCKET" "${dataBucket}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "APPDATA_PREFIX" "${getAppDataFilePrefix()}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "OPSDATA_BUCKET" "${operationsBucket}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "APPSETTINGS_PREFIX" "${getAppSettingsFilePrefix()}" format mode /]
    [#if !mode?has_content],[/#if]
    [@environmentVariable "CREDENTIALS_PREFIX" "${getCredentialsFilePrefix()}" format mode /]
    [#if buildCommit?has_content]
        [#if !mode?has_content],[/#if]
        [@environmentVariable "BUILD_REFERENCE" "${buildCommit}" format mode /]
    [/#if]
    [#if containerRunMode?has_content]
        [#if !mode?has_content],[/#if]
        [@environmentVariable "APP_RUN_MODE" "${containerRunMode?upper_case}" format mode /]
    [/#if]
    [#if appReference?has_content]
        [#if !mode?has_content],[/#if]
        [@environmentVariable "APP_REFERENCE" "${appReference}" format mode /]
    [/#if]
[/#macro]

[#macro containerBasicAttributes name image="" essential=true mode=""]
    [#switch mode]
        [#case "definition"]
        [#case ""]
            "Name" : "${name}",
            "Image" : "${getRegistryEndPoint("docker")}/${image?has_content?then(
                            image,
                            productName + "/" + buildDeploymentUnit + "-" + buildCommit)}",
            "Essential" : ${essential?c},
            [#break]
    [/#switch]
[/#macro]

[#macro containerExtraHosts hosts mode]
    [#switch mode]
        [#case "definition"]
        [#case ""]
            [#if hosts?has_content]
                "ExtraHosts" : [@toJSON hosts /],
            [/#if]
            [#break]
    [/#switch]
[/#macro]

[#macro containerVolume name containerPath hostPath="" readonly=false]
    [#switch containerListMode]
        [#case "volumes"]
            [#if volumeCount > 0],[/#if]
            {
                "Host": {
                    "SourcePath": "${hostPath}"
                },
                "Name": "${name}"
            }
            [#-- No break --]
        [#case "volumeCount"]
            [#assign volumeCount += 1]
            [#break]
            
        [#case "mountPoints"]
            [#if mountPointCount > 0],[/#if]
            {
                "SourceVolume": "${name}",
                "ContainerPath": "${containerPath}",
                "ReadOnly": ${readonly?c}
            }
            [#-- No break --]
        [#case "mountPointCount"]
            [#assign mountPointCount += 1]
        [#break]
    [/#switch]

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
                        [#-- DEPRECATED: These stem variables are deprecated --]
                        [#--             in favour of the containerListPolicy* variables --]
                        [#assign policyIdStem = formatComponentId(
                                                    tier,
                                                    component,
                                                    task,
                                                    container.Id)]
                        [#assign policyNameStem = getContainerName(container)]
                        [#include containerList]
                    [/#if]
                [/#list]
                [#break]
        [/#switch]
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

