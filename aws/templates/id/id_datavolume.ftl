[#-- Datavolume --]

[#-- Components --]
[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign componentConfiguration +=
    {
        DATAVOLUME_COMPONENT_TYPE  : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A persistant disk volume independent of compute"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Engine",
                    "Type" : STRING_TYPE,
                    "Values" : [ "ebs" ],
                    "Default" : "ebs"
                },
                {
                    "Names" : "Encrypted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : false
                },
                {
                    "Names" : "Size",
                    "Type" : NUMBER_TYPE,
                    "Default" : 20
                },
                {
                    "Names" : "VolumeType",
                    "Type" : STRING_TYPE,
                    "Default" : "gp2",
                    "Values" : [ "standard", "io1", "gp2", "sc1", "st1" ]
                },
                {
                    "Names" : "ProvisionedIops",
                    "Type" : NUMBER_TYPE,
                    "Default" : 100
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                }
            ]
        }
    }]

[#function getDataVolumeState occurrence]

    [#local core = occurrence.Core]
    [#local solution = occurrence.Configuration.Solution]

    [#if multiAZ!false ]
        [#local resourceZones = zones ]
    [#else]
        [#local resourceZones = [ zones[0] ] ]
    [/#if]

    [#local zoneResources = {} ]

    [#list resourceZones as zone ]
        [#local dataVolumeId = formatResourceId(AWS_EC2_EBS_RESOURCE_TYPE, core.Id, zone.Id )]
        [#local zoneResources += 
            {
                zone.Id : {
                    "ebsVolume" : {
                        "Id" : dataVolumeId,
                        "Name" : core.FullName,
                        "Type" : AWS_EC2_EBS_RESOURCE_TYPE
                    }
                }
            }
        ]
    [/#list]

    [#return
        {
            "Resources" : {
                "manualSnapshot" : {
                    "Id" : formatResourceId( AWS_EC2_EBS_MANUAL_SNAPSHOT_RESOURCE_TYPE, core.Id),
                    "Type" : AWS_EC2_EBS_MANUAL_SNAPSHOT_RESOURCE_TYPE
                },
                "Zones" : zoneResources
            },
            "Attributes" : {
                "VOLUME_NAME" : core.FullName,
                "ENGINE" : solution.Engine
            }
        }
    ]
[/#function]