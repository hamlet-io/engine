[#ftl]
[#macro aws_lg_cf_solution occurrence]
    [#return]
    [#-- ECS Log Group --]
    [#assign componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup
            mode=listMode
            id=componentLogGroupId
            name=formatComponentLogGroupName(tier, component) /]
    [/#if]
[/#macro]