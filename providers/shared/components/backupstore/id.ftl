[#ftl]

[@addComponent
    type=BACKUPSTORE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Store for holding backups"
            }
        ]
    attributes=
        [
            {
                "Names" : "Encryption",
                "Description" : "At-rest encryption management",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            },
            {
                "Names" : "Notifications",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Links",
                        "Description" : "Links to components which should receive the notifications",
                        "SubObjects": true,
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    },
                    {
                        "Names" : "Events",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : [
                            "BACKUP_JOB_STARTED",
                            "BACKUP_JOB_COMPLETED"
                        ],
                        "Values" : [
                            "BACKUP_JOB_STARTED",
                            "BACKUP_JOB_COMPLETED",
                            "COPY_JOB_STARTED",
                            "COPY_JOB_SUCCESSFUL",
                            "COPY_JOB_FAILED",
                            "RESTORE_JOB_STARTED",
                            "RESTORE_JOB_COMPLETED",
                            "RECOVERY_POINT_MODIFIED"
                        ]
                    }
                ]
            },
            {
                "Names" : "Lock",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Enable locking of backups to prevent unintended modification or deletion",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "MinRetention",
                        "Description" : "Minimum number of days to retain backups",
                        "Types" : NUMBER_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "MaxRetention",
                        "Description" : "Maximum number of days to retain backups. 0 = no maximum",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=BACKUPSTORE_COMPONENT_TYPE
    defaultGroup="solution"
    defaultPriority=150
/]

[@addChildComponent
    type=BACKUPSTORE_REGIME_COMPONENT_TYPE
    parent=BACKUPSTORE_COMPONENT_TYPE
    childAttribute="Regimes"
    linkAttributes="Regime"
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Defines a schedule of backups and the affected targets"
            }
        ]
    attributes=
        [
            {
                "Names" : "Rules",
                "Description" : "Rules defining the schedule of backups",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Permit the rule to be considered",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Schedule",
                        "Description" : "When to produce snapshots",
                        "Children" : [
                            {
                                "Names" : "Expression",
                                "Description" : "UTC based cron schedule to create backup snapshots",
                                "Types" : STRING_TYPE
                            },
                            {
                                "Names" : "PointInTimeSupport",
                                "Description" : "Enable ability for point-in-time restoration",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    },
                    {
                        "Names" : "StartWindow",
                        "Description" : "Period in minutes in which snapshot must start. 0 = no limit",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    },
                    {
                        "Names" : "FinishWindow",
                        "Description" : "Period in minutes after a snapshot has started in which it must finish. 0 = no limit",
                        "Types" : NUMBER_TYPE,
                        "Default" : 0
                    },
                    {
                        "Names" : "Lifecycle",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "Lifecycle the snapshot",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Offline",
                                "Types" : [NUMBER_TYPE],
                                "Description" : "Days until backup is moved to longer term storage. 0 = not moved",
                                "Default" : 0
                            },
                            {
                                "Names" : "Expiration",
                                "Types" : [NUMBER_TYPE],
                                "Description" : "Days until snapshot is deleted. Must be greater than Offline (if provided). 0 = not deleted",
                                "Default" : 0
                            }
                        ]
                    },
                    {
                        "Names" : "Copies",
                        "Description" : "Additional backup stores that should hold a copy of the snapshot",
                        "SubObjects" : true,
                        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                    }
                ]
            },
            {
                "Names" : "Conditions",
                "Description" : "Mechanisms to filter selected targets",
                "Children" : [
                    {
                        "Names" : "MatchesStore",
                        "Description" : "Enabled conditions must match those of the store and are ANDed",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "Permit matching against the backup store",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            },
                            {
                                "Names" : "Product",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Environment",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Segment",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            },
                            {
                                "Names" : "Tier",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : true
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Targets",
                "Description" : "Mechanisms to determine what should be backed up. Conditions are ORed",
                "Children" : [
                    {
                        "Names" : "All",
                        "Description" : "Consider all resources. Normally used with the MatchesStore condition",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "All resources are targets",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    },
                    {
                        "Names" : "Tag",
                        "Description" : "Include any target carrying a tag specific to the regime. Tag is added by linking from the component to the regime",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "Permit matching against a regime specific tag",
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    },
                    {
                        "Names" : "Components",
                        "Description" : "Specific components to include/exclude",
                        "Children" : [
                            {
                                "Names" : "Inclusions",
                                "Description" : "Specific components to include",
                                "SubObjects" : true,
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            },
                            {
                                "Names" : "Exclusions",
                                "Description" : "Specific components to exclude",
                                "SubObjects" : true,
                                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    }
                ]
            }
        ]
/]
