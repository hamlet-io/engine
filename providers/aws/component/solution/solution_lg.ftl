[#ftl]
[#macro aws_lg_cf_solution occurrence ]
    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#local componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup
            mode=listMode
            id=componentLogGroupId
            name=formatComponentLogGroupName(tier, component) /]
    [/#if]
[/#macro]