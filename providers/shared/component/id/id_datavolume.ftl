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
                            "Default" : "Etc/UTC"
                        },
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
