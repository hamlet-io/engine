[#-- ECS --]

[#-- Resources --]

[#function formatECSId tier component]
    [#return formatComponentResourceId(
                "ecs",
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

[#-- Container --]

[#-- Resources --]

[#function formatContainerId host container]
    [#return formatName(
                getContainerId(container),
                concatenate(host.Internal.OccurrenceIdExtensions,"-"))]
[/#function]

[#function formatContainerSecurityGroupIngressId resourceId container portRange]
    [#return formatDependentSecurityGroupIngressId(
                resourceId,
                getContainerId(container),
                portRange)]
[/#function]
