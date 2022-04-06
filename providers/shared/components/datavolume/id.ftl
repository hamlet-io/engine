[#ftl]

[@addComponent
    type=DATAVOLUME_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A persistant disk volume independent of compute"
            }
        ]
    attributes=
        [
            {
                "Names" : "Zones",
                "Description" : "A list of zoneIds to create virtual machines in, default is _all which will use all zones or the first for SingleAz",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_all" ]
            },
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Size",
                "Types" : NUMBER_TYPE,
                "Default" : 20
            },
            {
                "Names" : "VolumeType",
                "Types" : STRING_TYPE,
                "Default" : "gp2",
                "Values" : [ "standard", "io1", "gp2", "sc1", "st1" ]
            },
            {
                "Names" : "ProvisionedIops",
                "Types" : NUMBER_TYPE
            }
        ]
/]

[@addComponentDeployment
    type=DATAVOLUME_COMPONENT_TYPE
    defaultGroup="solution"
/]
