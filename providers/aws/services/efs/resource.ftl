[#ftl]

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

[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_EFS_RESOURCE_TYPE
    mappings=EFS_OUTPUT_MAPPINGS
/]

[@addOutputMapping 
    provider=AWS_PROVIDER
    resourceType=AWS_EFS_MOUNTTARGET_RESOURCE_TYPE
    mappings=EFS_MOUNTTARGET_MAPPINGS
/]

[#macro createEFS id name tier component encrypted kmsKeyId]
    [@cfResource
        id=id
        type="AWS::EFS::FileSystem"
        properties=
            {
                "PerformanceMode" : "generalPurpose",
                "FileSystemTags" : getCfTemplateCoreTags(name, tier, component)
            } +
            encrypted?then(
                {
                    "Encrypted" : true,
                    "KmsKeyId" : getReference(kmsKeyId, ARN_ATTRIBUTE_TYPE)
                },
                {}
            )
        outputs=EFS_OUTPUT_MAPPINGS
    /]
[/#macro]

[#macro createEFSMountTarget id efsId subnet securityGroups dependencies="" ]
    [@cfResource
        id=id
        type="AWS::EFS::MountTarget"
        properties=
            {
                "SubnetId" : subnet?is_enumerable?then(
                                subnet[0],
                                subnet
                ),
                "FileSystemId" : getReference(efsId),
                "SecurityGroups": getReferences(securityGroups)
            }
        outputs=EFS_MOUNTTARGET_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]
