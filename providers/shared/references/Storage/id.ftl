[#ftl]

[@addReference
    type=STORAGE_REFERENCE_TYPE
    pluralType="Storage"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A block volume storage configuration"
            }
        ]
    attributes=[
        {
            "Names" : "*",
            "Children" : [
                {
                    "Names" : "Volumes",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "Device",
                            "Types" : STRING_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names" : "MountPath",
                            "Types" : STRING_TYPE,
                            "Description" : "The OS path to mount the volume"
                        },
                        {
                            "Names" : "Size",
                            "Types" : NUMBER_TYPE,
                            "Mandatory" : true
                        },
                        {
                            "Names":  "Type",
                            "Types" : STRING_TYPE,
                            "Default" : "gp2"
                        },
                        {
                            "Names" : "Iops",
                            "Types" : NUMBER_TYPE
                        }
                    ]
                }
            ]
        }
    ]
/]
