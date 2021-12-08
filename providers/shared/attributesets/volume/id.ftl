[#ftl]

[@addAttributeSet
    type=VOLUME_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Defines the standard configuration of a storage volume"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Description" : "Should the volume be created",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Device",
            "Description" : "The deivce Id of the volume where the disk will be attached",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "MountPath",
            "Description" : "An OS path where the disk will be mounted",
            "Types" : STRING_TYPE
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
/]
