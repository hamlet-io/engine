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
                    "Ref" : VOLUME_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : ["computecluster", "ComputeCluster"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "Ref" : VOLUME_ATTRIBUTESET_TYPE
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
                    "Ref" : VOLUME_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : ["ecs", "ECS"],
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "Ref" : VOLUME_ATTRIBUTESET_TYPE
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
                            "Ref" : VOLUME_ATTRIBUTESET_TYPE
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
