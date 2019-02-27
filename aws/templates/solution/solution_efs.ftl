[#-- EFS --]

[#if componentType == EFS_COMPONENT_TYPE  ]

    [#list requiredOccurrences(
            getOccurrences(tier, component),
            deploymentUnit) as occurrence]

        [@cfDebug listMode occurrence false /]

        [#assign core = occurrence.Core]
        [#assign solution = occurrence.Configuration.Solution]
        [#assign resources = occurrence.State.Resources]
        [#assign zoneResources = occurrence.State.Resources.Zones]

        [#assign networkTier = getTier(tierId) ]       
        [#assign networkLink = networkTier.Network.Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]
        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign efsPort = 2049]

        [#assign efsId                  = resources["efs"].Id]
        [#assign efsFullName            = resources["efs"].Name]
        [#assign efsSecurityGroupId     = resources["sg"].Id]
        [#assign efsSecurityGroupName   = resources["sg"].Name]
        
        [#assign efsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
                                                efsSecurityGroupId, 
                                                efsPort)]

        [#if deploymentSubsetRequired("efs", true) ]
            [@createSecurityGroup
                mode=listMode
                tier=tier
                component=component
                id=efsSecurityGroupId
                name=efsSecurityGroupName
            /]

            [@createSecurityGroupIngress
                mode=listMode
                id=efsSecurityGroupIngressId
                port=efsPort
                cidr="0.0.0.0/0"
                groupId=efsSecurityGroupId
            /]
            
            [@createEFS 
                mode=listMode
                tier=tier
                id=efsId
                name=efsFullName
                component=component
                encrypted=solution.Encrypted
            /]

            [#list zones as zone ]
                [#assign zoneEfsMountTargetId   = zoneResources[zone.Id]["efsMountTarget"].Id]
                [@createEFSMountTarget
                    mode=listMode
                    id=zoneEfsMountTargetId
                    subnetId=getSubnets(tier, networkResources, zone.Id)
                    efsId=efsId
                    securityGroups=efsSecurityGroupId
                    dependencies=[efsId,efsSecurityGroupId]
                /]
            [/#list]
        [/#if ]
    [/#list]
[/#if]