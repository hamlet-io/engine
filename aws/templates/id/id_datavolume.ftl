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
                },
                {
                    "Names" : "Backup",
                    "Children" : [
                        {
                            "Names" : "Enabled",
                            "Type" : BOOLEAN_TYPE,
                            "Description" : "Create scheduled snapshots of the data volume",
                            "Default" : true
                        }
                        {
                            "Names" : "Schedule",
                            "Type" : STRING_TYPE,
                            "Description" : "Schedule in rate() or cron() formats",
                            "Default" : "rate(1 day)"
                        },
                        {
                            "Names" : "ScheduleTimeZone",
                            "Type" : STRING_TYPE,
                            "Description" : "When using a cron expression in Schedule sets the time zone to base it from",
                            "Default" : "Etc/UTC
                        }
                        {
                            "Names" : "RetentionPeriod",
                            "Type" : NUMBER_TYPE,
                            "Description" : "How long to keep snapshot for in days",
                            "Default" : 35
                        }
                    ]
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
                } + 
                (solution.Backup.Enabled)?then(
                    {
                        "taskCreateSnapshot" : {
                            "Id" : formatResourceId( AWS_SSM_MAINTENANCE_WINDOW_TASK_RESOURCE_TYPE, core.Id, "create", zone.Id),
                            "Name" : formatName(core.FullName, "create", zone.Name),
                            "Type" : AWS_SSM_MAINTENANCE_WINDOW_TASK_RESOURCE_TYPE
                        },
                        "taskDeleteSnapshot" : {
                            "Id" : formatResourceId( AWS_SSM_MAINTENANCE_WINDOW_TASK_RESOURCE_TYPE, core.Id, "delete", zone.Id),
                            "Name" : formatName(core.FullName, "delete", zone.Name),
                            "Type" : AWS_SSM_MAINTENANCE_WINDOW_TASK_RESOURCE_TYPE
                        }
                    },
                    {}
                )
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
            } + 
            (solution.Backup.Enabled)?then(
                {
                    "maintenanceWindow" : {
                        "Id" : formatResourceId(AWS_SSM_MAINTENANCE_WINDOW_RESOURCE_TYPE, core.Id ),
                        "Name" : core.FullName,
                        "Type" : AWS_SSM_MAINTENANCE_WINDOW_RESOURCE_TYPE
                    },
                    "windowTarget" : {
                        "Id" : formatResourceId(AWS_SSM_MAINTENANCE_WINDOW_TARGET_RESOURCE_TYPE, core.Id),
                        "Name" : core.FullName,
                        "Type" : AWS_SSM_MAINTENANCE_WINDOW_TARGET_RESOURCE_TYPE
                    },
                    "maintenanceServiceRole" : {
                        "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, "service", core.Id  ),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    },
                    "maintenanceLambdaRole" : { 
                        "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, "lambda", core.Id ),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE
                    }
                },
                {}
            ),
            "Attributes" : {
                "VOLUME_NAME" : core.FullName,
                "ENGINE" : solution.Engine
            }
        }
    ]
[/#function]