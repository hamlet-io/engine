[#ftl]
[#macro aws_lg_cf_solution occurrence ]
    [#local componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup
            mode=listMode
            id=componentLogGroupId
            name=formatComponentLogGroupName(tier, component) /]
    [/#if]
[/#macro]