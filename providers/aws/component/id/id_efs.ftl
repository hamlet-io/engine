[#-- Resources --]
[#assign AWS_EFS_RESOURCE_TYPE = "efs" ]
[#assign AWS_EFS_MOUNTTARGET_RESOURCE_TYPE = "efsMountTarget" ]

[#function formatEFSId tier component extensions...]
    [#return formatComponentResourceId(
        AWS_EFS_RESOURCE_TYPE
        tier,
        component,
        extensions)]
[/#function]

[#function formatDependentEFSMountTargetId resourceId extensions...]
    [#return formatDependentResourceId(
                AWS_EFS_MOUNTTARGET_RESOURCE_TYPE
                resourceId,
                extensions)]
[/#function]

[#macro aws_efs_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getEFSState(occurrence)]
[/#macro]

[#function getEFSState occurrence]

    [#local core = occurrence.Core]

    [#local id = formatEFSId( core.Tier, core.Component, occurrence) ]

    [#local zoneResources = {} ]
    [#list zones as zone ]
        [#local zoneResources +=
            {
                zone.Id : {
                    "efsMountTarget" : {
                        "Id" : formatDependentResourceId(AWS_EFS_MOUNTTARGET_RESOURCE_TYPE, id, zone.Id),
                        "Type" : AWS_EFS_MOUNTTARGET_RESOURCE_TYPE
                    }
                }
            }
        ]
    [/#list]

    [#return
        {
            "Resources" : {
                "efs" : {
                    "Id" : id,
                    "Name" : formatComponentFullName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_EFS_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(id),
                    "Name" : core.FullName,
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                },
                "Zones" : zoneResources
            },
            "Attributes" : {
                "EFS" : getExistingReference(id)
            }
        }
    ]
[/#function]

[#macro aws_efsmount_cf_state occurrence parent={} baseState={}  ]
    [#assign componentState = getEFSMountState(occurrence, parent)]
[/#macro]

[#function getEFSMountState occurrence parent ]
    [#local configuration = occurrence.Configuration.Solution]

    [#local efsId = parent.State.Attributes["EFS"] ]

    [#return
        {
            "Resources" : {},
            "Attributes" : {
                "EFS" : efsId,
                "DIRECTORY" : configuration.Directory

            }
        }
    ]
[/#function]