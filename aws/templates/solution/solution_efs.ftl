[#-- EFS --]

[#if componentType == EFS_COMPONENT_TYPE  ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign configuration = occurrence.Configuration]
        [#assign resources = occurrence.State.Resources]

        [#assign efsId              = resources["efs"].Id]
        [#assign efsFullName        = resources["efs"].Name]
        [#assign efsMountTargetId   = resources["efsMountTarget"].Id]
        [#assign efsSecurityGroupId = resources["sg"].Id]
        
        [#if deploymentSubsetRequired("efs", true) ]
            [@createComponentSecurityGroup
                mode=listMode
                tier=tier
                component=component
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
        [/#if ]
    [/#list]
[/#if]