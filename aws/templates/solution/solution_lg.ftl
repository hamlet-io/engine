[#-- ECS Log Group --]
[#if componentType == "lg"]
    [#assign componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup 
            mode=solutionListMode
            id=componentLogGroupId
            name=formatComponentLogGroupName(tier, component) /]
    [/#if]
[/#if]