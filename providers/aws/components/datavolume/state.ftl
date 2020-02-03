[#ftl]

[#macro aws_datavolume_cf_state occurrence parent={} ]
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

    [#assign componentState =
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
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
                    },
                    "maintenanceLambdaRole" : {
                        "Id" : formatResourceId( AWS_IAM_ROLE_RESOURCE_TYPE, "lambda", core.Id ),
                        "Type" : AWS_IAM_ROLE_RESOURCE_TYPE,
                        "IncludeInDeploymentState" : false
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
[/#macro]