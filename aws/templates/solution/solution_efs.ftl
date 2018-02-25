[#-- EFS --]
[#if componentType == "efs" && deploymentSubsetRequired("efs", true) ]
    [#assign efs = component.EFS]

    [#list getOccurrences(component, tier, component, deploymentUnit) as occurrence]
        [#assign efsId = formatEFSId(
                            tier, 
                            component,
                            occurrence)]
        
        [#assign efsFullName = componentFullName]

        [#assign efsMountTargetId = formatDependentEFSMountTargetId(
                                        efsId)]
        
        [#assign efsSecurityGroupId = formatComponentSecurityGroupId(
                                        tier, 
                                        component,
                                        "efs")]

        [@createComponentSecurityGroup
            mode=listMode
            tier=tier
            component=component
            extensions="efs"
        /]
        
        [@createEFS 
            mode=listMode
            tier=tier
            id=efsId
            name=efsFullName
            component=component
        /]

        [@createEFSMountTarget
            mode=listMode
            tier=tier
            efsId=efsId
            securityGroups=efsSecurityGroupId
            dependencies=[efsId,efsSecurityGroupId]
        /]
    [/#list]
[/#if]