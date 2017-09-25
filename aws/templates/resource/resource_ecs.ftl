[#-- ECS --]

[#macro createECSTask mode id containers role="" dependencies=""]

    [#local definitions = [] ]
    [#local volumes = [] ]
    [#list containers?values as container]
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
                    volume.HostPath?has_content?then(
                        {
                            "Host" : {
                                "SourcePath" : volume.HostPath
                            }
                        },
                        {}
                    )
                ]
            ]
        [/#list]
        [#local portMappings = [] ]
        [#list (container.PortMappings!{}) as portMapping]
            [#local portMappings +=
                [
                    {
                        "ContainerPort" : portMapping.ContainerPort,
                        "HostPort" : portMapping.HostPort
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
            {
                "Name" : container.Name,
                "Image : container.Image +
                            container.Version?has_content?then(
                                ":" + container.Version,
                                ""
                            ),
                "Essential" : container.Essential,
                "MemoryReservation" : container.Memory,
                "LogConfiguration" : 
                    {
                        "LogDriver" : container.LogDriver
                    } + 
                    container.LogOptions?has_content?then(
                        {
                            "Options" : container.LogOptions
                        },
                        {}
                    )
                }
            } +
            environment?has_content?then(
                {
                    "Environment" : environment
                },
                {}
            ) +
            mountPoints?has_content?then(
                {
                    "MountPoints" : mountPoints
                },
                {}
            ) +
            extraHosts?has_content?then(
                {
                    "ExtraHosts" : extraHosts
                },
                {}
            ) +
            container.MaximumMemory?has_content?then(
                {
                    "Memory" : container.MaximumMemory
                },
                {}
            ) +
            container.Cpu?has_content?then(
                {
                    "Cpu" : container.Cpu
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
    [/#list]

    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ECS::TaskDefinition"
        properties=
            {
                "ContainerDefinitions" : definitions
            } + 
            volumes?has_content?then(
                {
                    "Volumes" : volumes
                },
                {}
            ) +
            role?has_content?then(
                {
                    "TaskRoleArn" : getReference(role, ARN_ATTRIBUTE_TYPE)
                },
                {}
            )
        dependencies=dependencies
    /]
[/#macro]

[#macro createECSService mode id ecsId desiredCount taskId loadBalancers roleId="" dependencies=""]


    [@cfTemplate
        mode=mode
        id=id
        type="AWS::ECS::Service"
        properties=
            {
                "Cluster" : getExistingReference(ecsId),
                "DeploymentConfiguration" : 
                    (desiredCount > 1)?then(
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 50
                        },
                        {
                            "MaximumPercent" : 100,
                            "MinimumHealthyPercent" : 0
                        }
                    ),
                "DesiredCount" : desiredCount,
                "TaskDefinition" : getReference(taskId)
            } +
            loadBalancers?has_content?then(
                {
                    "LoadBalancers" : loadBalancers,
                    "Role" : getReference(roleId)
                },
                {}
            )
        dependencies=dependencies
    /]
[/#macro]

