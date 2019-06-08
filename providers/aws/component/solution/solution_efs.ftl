[#ftl]
[#macro aws_efs_cf_solution occurrence ]
    [@cfDebug listMode occurrence false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]
    [#local zoneResources = occurrence.State.Resources.Zones]

    [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@cfException listMode "Network could not be found" networkLink /]
        [#return]
    [/#if]

    [#local networkConfiguration = networkLinkTarget.Configuration.Solution]
    [#local networkResources = networkLinkTarget.State.Resources ]

    [#local vpcId = networkResources["vpc"].Id ]

    [#local efsPort = 2049]

    [#local efsId                  = resources["efs"].Id]
    [#local efsFullName            = resources["efs"].Name]
    [#local efsSecurityGroupId     = resources["sg"].Id]
    [#local efsSecurityGroupName   = resources["sg"].Name]

    [#local efsSecurityGroupIngressId = formatDependentSecurityGroupIngressId(
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
            [#local zoneEfsMountTargetId   = zoneResources[zone.Id]["efsMountTarget"].Id]
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
[/#macro]