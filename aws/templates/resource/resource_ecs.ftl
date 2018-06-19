[#-- ECS --]

[#macro createECSTask mode id containers networkMode="" delegatedDeployment=false role="" dependencies=""]

    [#local definitions = [] ]
    [#local volumes = [] ]
    [#list containers as container]
        [#local mountPoints = [] ]
        [#list (container.Volumes!{}) as name,volume]
            [#local mountPoints +=
                [
                    {
                        "ContainerPath" : volume.ContainerPath,
                        "SourceVolume" : name,
                        "ReadOnly" : volume.ReadOnly
                    }
                ]
            ]
            [#local volumes +=
                [
                    {
                        "Name" : name
                    } +
                    attributeIfTrue(
                        "Host",
                        volume.HostPath?has_content,
                        {"SourcePath" : volume.HostPath!""})
                ]
            ]
        [/#list]
        [#local portMappings = [] ]
        [#list (container.PortMappings![]) as portMapping]
            [#local portMappings +=
                [
                    {
                        "ContainerPort" : ports[portMapping.ContainerPort].Port,
                        "HostPort" : portMapping.DynamicHostPort?then(0, ports[portMapping.HostPort].Port)
                    }
                ]
            ]
        [/#list]
        [#local environment = [] ]
        [#list (container.Environment!{}) as name,value]
            [#local environment +=
                [
                    {
                        "Name" : name,
                        "Value" : value
                    }
                ]
            ]
        [/#list]
        [#local extraHosts = [] ]
        [#list (container.Hosts!{}) as name,value]
            [#local extraHosts +=
                [
                    {
                        "Hostname" : name,
                        "IpAddress" : value
                    }
                ]
            ]
        [/#list]
        [#local definitions +=
            [
                {
                    "Name" : container.Name,
                    "Image" :
                        formatRelativePath(
                            container.RegistryEndPoint,
                            container.Image +
                                container.ImageVersion?has_content?then(
                                    ":" + container.ImageVersion,
                                    ""
                                )
                            ),
                    "Essential" : container.Essential,
                    "MemoryReservation" : container.MemoryReservation,
                    "LogConfiguration" : 
                        {
                            "LogDriver" : container.LogDriver
                        } + 
                        attributeIfContent("Options", container.LogOptions)
                } +
                attributeIfContent("Environment", environment) +
                attributeIfContent("MountPoints", mountPoints) +
                attributeIfContent("ExtraHosts", extraHosts) +
                attributeIfContent("Memory", container.MaximumMemory!"") +
                attributeIfContent("Cpu", container.Cpu!"") +
                attributeIfContent("PortMappings", portMappings) + 
                attributeIfContent("NetworkMode", networkMode)
            ]
        ]
    [/#list]

    [#local taskProperties = {
        "ContainerDefinitions" : definitions
        } + 
        attributeIfContent("Volumes", volumes)  + 
        attributeIfContent("TaskRoleArn", role, getReference(role, ARN_ATTRIBUTE_TYPE))
    ]

    [#if delegatedDeployment ]
        [#-- Allows for container definitions to be written to a config file for processing by another service (e.g. Jenkins) --]
        [@cfConfig
            mode=listMode
            content=taskProperties
        /]
    [#else]
        [@cfResource
            mode=mode
            id=id
            type="AWS::ECS::TaskDefinition"
            properties=taskProperties
            dependencies=dependencies
        /]
    [/#if]
[/#macro]

[#macro createECSService mode id ecsId desiredCount taskId loadBalancers networkMode="" subnets=[] securityGroups=[] roleId="" dependencies=""]

    [@cfResource
        mode=mode
        id=id
        type="AWS::ECS::Service"
        properties=
            {
                "Cluster" : getExistingReference(ecsId),
                "DesiredCount" : desiredCount,
                "TaskDefinition" : getReference(taskId),
                "DeploymentConfiguration" :
                    (desiredCount > 1)?then(
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 50
                        },
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 0
                        })
            } + 
            valueIfContent(
                {
                    "LoadBalancers" : loadBalancers![],
                    "Role" : getReference(roleId)
                },
                loadBalancers![]) +
            valueIfTrue(
                {
                    "NetworkConfiguration" : {
                        "AwsvpcConfiguration" : {
                            "SecurityGroups" : securityGroups,
                            "Subnets" : subnets
                        }
                    }
                },
                networkMode == "awsvpc"
            )
        dependencies=dependencies
    /]
[/#macro]

