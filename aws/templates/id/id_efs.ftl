[#-- EFS --]

[#assign EFS_RESOURCE_TYPE = "efs" ]
[#assign EFS_MOUNTTARGET_RESOURCE_TYPE = "efsMountTarget" ]

[#function formatEFSId tier component extensions...]
    [#return formatComponentResourceId(
        EFS_RESOURCE_TYPE
        tier,
        component,
        extensions)]
[/#function]

[#function formatDependentEFSMountTargetId resourceId extensions...]
    [#return formatDependentResourceId(
                EFS_MOUNTTARGET_RESOURCE_TYPE
                resourceId,
                extensions)]
[/#function]

[#assign componentConfiguration +=
    {
        "efs"  : [
        ]
    }]
    
[#function getEFSState occurrence]
    [#return
        {
            "Resources" : {},
            "Attributes" : {}
        }
    ]
[/#function]