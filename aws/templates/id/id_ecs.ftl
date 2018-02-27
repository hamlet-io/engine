[#-- ECS --]

[#assign ECS_RESOURCE_TYPE = "ecs" ]

[#function formatECSId tier component]
    [#return formatComponentResourceId(
                ECS_RESOURCE_TYPE,
                tier,
                component)]
[/#function]

[#function formatECSServiceId tier component service]
    [#return formatComponentResourceId(
                "ecsService",
                tier,
                component,
                service)]
[/#function]

[#function formatECSTaskId tier component task]
    [#return formatComponentResourceId(
                "ecsTask",
                tier,
                component,
                task)]
[/#function]

[#function formatECSRoleId tier component]
    [#-- TODO: Use formatDependentRoleId() --]
    [#return formatComponentRoleId(
                tier,
                component)]
[/#function]

[#function formatECSServiceRoleId tier component]
    [#-- TODO: Use formatDependentRoleId() --]
    [#return formatComponentRoleId(
                tier,
                component,
                "service")]
[/#function]

[#function formatECSSecurityGroupId tier component]
    [#return formatComponentSecurityGroupId(
                tier,
                component)]
[/#function]

[#assign componentConfiguration +=
    {
        "ecs" : [
            {
                "Name" : "ClusterWideStorage",
                "Default" : false
            }
        ],
        "service" : [
            {
                "Name" : "DesiredCount",
                "Default" : -1
            },
            {
                "Name" : "Containers",
                "Default" : {}
            },
            {
                "Name" : "UseTaskRole",
                "Default" : true
            }
        ],
        "task" : [
            {
                "Name" : "Containers",
                "Default" : {}
            },
            {
                "Name" : "UseTaskRole",
                "Default" : true
            } 
        ]
    }]
    
[#function getECSState occurrence]
    [#return
        {
            "Resources" : {},
            "Attributes" : {}
        }
    ]
[/#function]

[#function getTaskState occurrence]
    [#return
        {
            "Resources" : {},
            "Attributes" : {}
        }
    ]
[/#function]

[#function getServiceState occurrence]
    [#return
        {
            "Resources" : {},
            "Attributes" : {}
        }
    ]
[/#function]

[#-- Container --]

[#function formatContainerFragmentId occurrence container]
    [#return formatName(
                getContainerId(container),
                occurrence.Core.Instance.Id,
                occurrence.Core.Version.Id)]
[/#function]

[#function formatContainerSecurityGroupIngressId resourceId container portRange]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                getContainerId(container),
                portRange)]
[/#function]
