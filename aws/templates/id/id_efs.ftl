[#-- EFS --]

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

[#-- Components --]

[#assign EFS_COMPONENT_TYPE = "efs" ]

[#assign componentConfiguration +=
    {
        EFS_COMPONENT_TYPE  : {

        }

    }]

[#function getEFSState occurrence]

    [#local core = occurrence.Core]

    [#local id = formatEFSId( core.Tier, core.Component, occurrence) ]

    [#return
        {
            "Resources" : {
                "efs" : {
                    "Id" : id,
                    "Name" : formatComponentFullName(core.Tier, core.Component, occurrence),
                    "Type" : AWS_EFS_RESOURCE_TYPE
                },
                "efsMountTarget" : {
                    "Id" : formatDependentResourceId(AWS_EFS_MOUNTTARGET_RESOURCE_TYPE, efsId),
                    "Type" : AWS_EFS_MOUNTTARGET_RESOURCE_TYPE
                },
                "sg" : {
                    "Id" : formatDependentSecurityGroupId(id),
                    "Type" : AWS_VPC_SECURITY_GROUP_RESOURCE_TYPE
                }
            },
            "Attributes" : {}
        }
    ]
[/#function]