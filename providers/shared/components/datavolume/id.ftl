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
                "Names" : "Engine",
                "Types" : STRING_TYPE,
                "Values" : [ "ebs" ],
                "Default" : "ebs"
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
                "Types" : NUMBER_TYPE,
                "Default" : 100
            },
            {
                "Names" : "Backup",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Description" : "Create scheduled snapshots of the data volume",
                        "Default" : true
                    }
                    {
                        "Names" : "Schedule",
                        "Types" : STRING_TYPE,
                        "Description" : "Schedule in rate() or cron() formats",
                        "Default" : "rate(1 day)"
                    },
                    {
                        "Names" : "ScheduleTimeZone",
                        "Types" : STRING_TYPE,
                        "Description" : "When using a cron expression in Schedule sets the time zone to base it from",
                        "Default" : "Etc/UTC"
                    },
                    {
                        "Names" : "RetentionPeriod",
                        "Types" : NUMBER_TYPE,
                        "Description" : "How long to keep snapshot for in days",
                        "Default" : 35
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=DATAVOLUME_COMPONENT_TYPE
    defaultGroup="solution"
/]
