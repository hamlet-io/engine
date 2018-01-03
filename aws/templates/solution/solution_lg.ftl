[#-- ECS Log Group --]
[#if componentType == "lg"]
    [#assign componentLogGroupId = formatComponentLogGroupId(tier, component)]
    [#if deploymentSubsetRequired("lg", true) &&
            isPartOfCurrentDeploymentUnit(componentLogGroupId)]
        [@createLogGroup 
            mode=listMode
            id=componentLogGroupId
            name=formatComponentLogGroupName(tier, component) /]
    [/#if]
[/#if]