[#-- EFS --]

[#if componentType == EFS_COMPONENT_TYPE  ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign resources = occurrence.State.Resources]
        [#assign zoneResources = occurrence.State.Resources.Zones]

        [#assign efsId              = resources["efs"].Id]
        [#assign efsFullName        = resources["efs"].Name]
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
                encrypted=configuration.Encrypted
            /]

            [#list zones as zone ]
                [#assign zoneEfsMountTargetId   = zoneResources[zone.Id]["efsMountTarget"].Id]
                [@createEFSMountTarget
                    mode=listMode
                    id=zoneEfsMountTargetId
                    subnetId=formatSubnetId(tier, zone)
                    efsId=efsId
                    securityGroups=efsSecurityGroupId
                    dependencies=[efsId,efsSecurityGroupId]
                /]
            [/#list]
        [/#if ]
    [/#list]
[/#if]