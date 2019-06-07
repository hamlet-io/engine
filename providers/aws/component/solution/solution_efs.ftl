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

        [#assign networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

        [#assign networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

        [#if ! networkLinkTarget?has_content ]
            [@cfException listMode "Network could not be found" networkLink /]
            [#break]
        [/#if]

        [#assign networkConfiguration = networkLinkTarget.Configuration.Solution]
        [#assign networkResources = networkLinkTarget.State.Resources ]

        [#assign vpcId = networkResources["vpc"].Id ]

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
                id=efsSecurityGroupId
                name=efsSecurityGroupName
                occurrence=occurrence
                vpcId=vpcId
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
                tier=core.Tier
                id=efsId
                name=efsFullName
                component=core.Component
                encrypted=solution.Encrypted
            /]

            [#list zones as zone ]
                [#assign zoneEfsMountTargetId   = zoneResources[zone.Id]["efsMountTarget"].Id]
                [@createEFSMountTarget
                    mode=listMode
                    id=zoneEfsMountTargetId
                    subnet=getSubnets(core.Tier, networkResources, zone.Id, true, false)
                    efsId=efsId
                    securityGroups=efsSecurityGroupId
                    dependencies=[efsId,efsSecurityGroupId]
                /]
            [/#list]
        [/#if ]
    [/#list]
[/#if]