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
        EFS_RESOURCE_TYPE : EFS_OUTPUT_MAPPINGS,
        EFS_MOUNTTARGET_RESOURCE_TYPE : EFS_MOUNTTARGET_MAPPINGS
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

[#macro createEFSMountTarget mode tier efsId securityGroups dependencies="" ]
    [#assign subnets = getSubnets(tier,true,true) ]
    [#list subnets as subnet ]
        [#assign efsMountTargetId = formatDependentEFSMountTargetId(
                                        efsId
                                        subnet.zone.Id)]
        [@cfResource
            mode=mode
            id=efsMountTargetId
            type="AWS::EFS::MountTarget"
            properties=
                {
                    "SubnetId" : subnet.subnetId,
                    "FileSystemId" : getReference(efsId),
                    "SecurityGroups": getReferences(securityGroups)
                }
            outputs=EFS_MOUNTTARGET_MAPPINGS
            dependencies=dependencies
        /]
    [/#list]
[/#macro]
