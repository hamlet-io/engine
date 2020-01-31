[#ftl]

[#macro aws_efs_cf_state occurrence parent={} ]
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

    [#assign componentState =
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
[/#macro]

[#macro aws_efsmount_cf_state occurrence parent={} ]
    [#local configuration = occurrence.Configuration.Solution]

    [#local efsId = parent.State.Attributes["EFS"] ]

    [#assign componentState =
        {
            "Resources" : {},
            "Attributes" : {
                "EFS" : efsId,
                "DIRECTORY" : configuration.Directory

            }
        }
    ]
[/#macro]