[#-- EFS --]

[#assign EFS_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        }
    }
]

[#assign EFS_MOUNTTARGET_MAPPINGS = 
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        ARN_ATTRIBUTE_TYPE : { 
            "UseRef" : true
        }
    }
]

[#assign outputMappings +=
    {
        AWS_EFS_RESOURCE_TYPE : EFS_OUTPUT_MAPPINGS,
        AWS_EFS_MOUNTTARGET_RESOURCE_TYPE : EFS_MOUNTTARGET_MAPPINGS
    }
]

[#macro createEFS mode id name tier component]
    [@cfResource
        mode=mode
        id=id
        type="AWS::EFS::FileSystem"
        properties=
            {
                "PerformanceMode" : "generalPurpose",
                "FileSystemTags" : getCfTemplateCoreTags(name, tier, component)
            } 
        outputs=EFS_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createEFSMountTarget mode id efsId subnetId securityGroups dependencies="" ]
    [@cfResource
        mode=mode
        id=efsMountTargetId
        type="AWS::EFS::MountTarget"
        properties=
            {
                "SubnetId" : getReference(subnetId),
                "FileSystemId" : getReference(efsId),
                "SecurityGroups": getReferences(securityGroups)
            }
        outputs=EFS_MOUNTTARGET_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
