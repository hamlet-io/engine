[#ftl]
[#macro aws_efs_cf_generationcontract_solution occurrence ]
    [@addDefaultGenerationContract subsets="template" /]
[/#macro]

[#macro aws_efs_cf_setup_solution occurrence ]
    [@debug message="Entering" context=occurrence enabled=false /]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]
    [#local resources = occurrence.State.Resources]
    [#local zoneResources = occurrence.State.Resources.Zones]

    [#local networkLink = getOccurrenceNetwork(occurrence).Link!{} ]

    [#local networkLinkTarget = getLinkTarget(occurrence, networkLink ) ]

    [#if ! networkLinkTarget?has_content ]
        [@fatal message="Network could not be found" context=networkLink /]
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

    [#-- Baseline component lookup --]
    [#local baselineLinks = getBaselineLinks(occurrence, [ "Encryption"] )]
    [#local baselineComponentIds = getBaselineComponentIds(baselineLinks)]
    [#local cmkKeyId = baselineComponentIds["Encryption" ]]

    [#if deploymentSubsetRequired("efs", true) ]
        [@createSecurityGroup
            id=efsSecurityGroupId
            name=efsSecurityGroupName
            occurrence=occurrence
            vpcId=vpcId
        /]

        [@createSecurityGroupIngress
            id=efsSecurityGroupIngressId
            port=efsPort
            cidr="0.0.0.0/0"
            groupId=efsSecurityGroupId
        /]

        [@createEFS
            tier=core.Tier
            id=efsId
            name=efsFullName
            component=core.Component
            encrypted=solution.Encrypted
            kmsKeyId=cmkKeyId
        /]

        [#list zones as zone ]
            [#local zoneEfsMountTargetId   = zoneResources[zone.Id]["efsMountTarget"].Id]
            [@createEFSMountTarget
                id=zoneEfsMountTargetId
                subnet=getSubnets(core.Tier, networkResources, zone.Id, true, false)
                efsId=efsId
                securityGroups=efsSecurityGroupId
                dependencies=[efsId,efsSecurityGroupId]
            /]
        [/#list]
    [/#if ]
[/#macro]
