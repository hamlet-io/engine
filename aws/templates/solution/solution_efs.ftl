[#-- EFS --]
[#if (componentType == "efs") && deploymentSubsetRequired("s3", true) ]
    [#assign efs = component.EFS]

    [#list getOccurrences(component, deploymentUnit) as occurrence]
        [#assign efsId = formatEFSId(
                            tier, 
                            component,
                            occurrence)]
        
        [#assign efsFullName = componentFullName]

        [#assign efsMountTargetId = formatDependentEFSMountTargetId(
                                        efsId)]
        
        [#assign efsSecurityGroupId = formatDependentComponentSecurityGroupId(
                                        tier, 
                                        component,
                                        efsId)]

        [@createDependentComponentSecurityGroup
            mode=listMode
            tier=tier
            component=component
            resourceId=efsId
            resourceName=efsName
        /]

        [@createEFS 
            mode=listMode
            id=efsId
            name=efsFullName
            component=component
        /]

        [@createEFSMountTarget
            mode=listMode
            id=efsMountTargetId
            tier=tier
            efs=efsId
            securityGroups=efsSecurityGroupId
            dependecies=efsId
        /]

    [/#list]
[/#if]