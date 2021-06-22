[#ftl]

[@addReference
    type=STORAGE_REFERENCE_TYPE
    pluralType="Storage"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Storage configuration for components"
            }
        ]
    attributes=[
        {
            "Names" : ["bastion", "Bastion"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "AttributeSet" : VOLUME_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : ["computecluster", "ComputeCluster"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "AttributeSet" : VOLUME_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "Tier",
                    "Description" : "The storage tier to use for all volumes",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Replication",
                    "Description": "The type of storage replication to use",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : ["ec2", "EC2"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "AttributeSet" : VOLUME_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : ["ecs", "ECS"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "AttributeSet" : VOLUME_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : ["es", "ElasticSearch"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "Children" : [
                        {
                            "Names" : ["data", "codeontap"],
                            "Description" : "A fixed volume to use for ES Data storage",
                            "Children" : [
                                {
                                    "Names" : "Enabled",
                                    "Description" : "Should the volume be created",
                                    "Types" : BOOLEAN_TYPE,
                                    "Default" : true
                                },
                                {
                                    "Names" : "Size",
                                    "Description" : "The size in GB of the volume",
                                    "Types" : NUMBER_TYPE,
                                    "Mandatory" : true
                                },
                                {
                                    "Names":  "Type",
                                    "Description" : "The type of volume to provision - see provider for available types",
                                    "Types" : STRING_TYPE,
                                    "Default" : "gp2"
                                },
                                {
                                    "Names" : "Iops",
                                    "Description" : "For volume types which support provisioned IOPS, this sets the requested IOPS",
                                    "Types" : NUMBER_TYPE
                                }
                            ]
                        }
                    ]
                }
            ]
        },
        {
            "Names" : ["storageAccount"],
            "Description" : "Azure Storage Account configuration",
            "Children" : [
                {
                    "Names" : "Tier",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Type",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "Replication",
                    "Types" : STRING_TYPE
                },
                {
                    "Names": "AccessTier",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "HnsEnabled",
                    "Types" : BOOLEAN_TYPE
                }
            ]
        }
    ]
/]
