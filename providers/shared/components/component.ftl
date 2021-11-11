[#ftl]

[#-- Legacy type mappings --]
[#assign legacyTypeMapping = {} ]

[#-- Provides generic component macros --]
[#assign SHARED_COMPONENT_TYPE = "shared" ]

[#-- Known component types --]
[#assign ADAPTOR_COMPONENT_TYPE = "adaptor"]

[#assign APIGATEWAY_COMPONENT_TYPE = "apigateway"]
[#assign APIGATEWAY_USAGEPLAN_COMPONENT_TYPE = "apiusageplan"]
[#assign APIGATEWAY_COMPONENT_DOCS_EXTENSION = "docs"]

[#assign BASELINE_COMPONENT_TYPE = "baseline" ]
[#assign BASELINE_DATA_COMPONENT_TYPE = "baselinedata" ]
[#assign BASELINE_KEY_COMPONENT_TYPE = "baselinekey" ]

[#assign BASTION_COMPONENT_TYPE = "bastion" ]

[#assign CACHE_COMPONENT_TYPE = "cache" ]

[#assign CDN_COMPONENT_TYPE = "cdn"]
[#assign CDN_ROUTE_COMPONENT_TYPE = "cdnroute" ]

[#assign CLIENTVPN_COMPONENT_TYPE = "clientvpn" ]

[#assign COMPUTECLUSTER_COMPONENT_TYPE = "computecluster"]

[#assign CONFIGSTORE_COMPONENT_TYPE = "configstore" ]
[#assign CONFIGSTORE_BRANCH_COMPONENT_TYPE = "configbranch"]

[#assign CONTAINERHOST_COMPONENT_TYPE="containerhost"]
[#assign CONTAINERSERVICE_COMPONENT_TYPE="containerservice"]
[#assign CONTAINERTASK_COMPONENT_TYPE="containertask"]

[#assign CONTENTHUB_HUB_COMPONENT_TYPE = "contenthub"]
[#assign CONTENTHUB_NODE_COMPONENT_TYPE = "contentnode"]

[#assign CORRESPONDENT_COMPONENT_TYPE = "correspondent"]

[#assign DATAFEED_COMPONENT_TYPE = "datafeed" ]

[#assign DATAPIPELINE_COMPONENT_TYPE = "datapipeline"]

[#assign DATASET_COMPONENT_TYPE = "dataset"]

[#assign DATAVOLUME_COMPONENT_TYPE = "datavolume" ]

[#assign DB_COMPONENT_TYPE = "db" ]
[#assign DB_LEGACY_COMPONENT_TYPE = "rds" ]
[#assign legacyTypeMapping += { DB_LEGACY_COMPONENT_TYPE : DB_COMPONENT_TYPE } ]

[#assign DIRECTORY_COMPONENT_TYPE = "directory" ]

[#assign EC2_COMPONENT_TYPE = "ec2"]

[#assign ECS_COMPONENT_TYPE = "ecs" ]
[#assign ECS_SERVICE_COMPONENT_TYPE = "service" ]
[#assign ECS_TASK_COMPONENT_TYPE = "task" ]

[#assign FILESHARE_COMPONENT_TYPE = "fileshare" ]
[#assign FILESHARE_MOUNT_COMPONENT_TYPE = "filesharemount"]

[#assign FILESHARE_LEGACY_COMPONENT_TYPE = "efs" ]
[#assign legacyTypeMapping += { FILESHARE_LEGACY_COMPONENT_TYPE : FILESHARE_COMPONENT_TYPE } ]

[#assign FILESHARE_MOUNT_LEGACY_COMPONENT_TYPE = "efsmount" ]
[#assign legacyTypeMapping += { FILESHARE_MOUNT_LEGACY_COMPONENT_TYPE : FILESHARE_MOUNT_COMPONENT_TYPE } ]

[#assign ES_COMPONENT_TYPE = "es"]
[#assign ES_LEGACY_COMPONENT_TYPE = "elasticsearch"]
[#assign legacyTypeMapping += { ES_LEGACY_COMPONENT_TYPE : ES_COMPONENT_TYPE } ]

[#assign EXTERNALNETWORK_COMPONENT_TYPE = "externalnetwork" ]
[#assign EXTERNALNETWORK_CONNECTION_COMPONENT_TYPE = "externalnetworkconnection" ]

[#assign EXTERNALSERVICE_COMPONENT_TYPE = "externalservice" ]
[#assign EXTERNALSERVICE_ENDPOINT_COMPONENT_TYPE = "externalserviceendpoint" ]

[#assign FEDERATEDROLE_COMPONENT_TYPE = "federatedrole" ]
[#assign FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE = "federatedroleassignment" ]

[#assign FILETRANSFER_COMPONENT_TYPE = "filetransfer"]

[#assign FIREWALL_COMPONENT_TYPE = "firewall"]
[#assign FIREWALL_RULE_COMPONENT_TYPE = "firewallrule"]
[#assign FIREWALL_DESTINATION_COMPONENT_TYPE = "firewalldestination"]

[#assign GLOBALDB_COMPONENT_TYPE = "globaldb" ]

[#assign HEALTHCHECK_COMPONENT_TYPE = "healthcheck" ]

[#assign HOSTING_PLATFORM_COMPONENT_TYPE = "hostingplatform"]

[#assign INTERNALTEST_COMPONENT_TYPE = "internaltest" ]

[#assign LAMBDA_COMPONENT_TYPE = "lambda"]
[#assign LAMBDA_FUNCTION_COMPONENT_TYPE = "function"]

[#assign LB_COMPONENT_TYPE = "lb" ]
[#assign LB_PORT_COMPONENT_TYPE = "lbport" ]
[#assign LB_LEGACY_COMPONENT_TYPE = "alb" ]
[#assign legacyTypeMapping += { LB_LEGACY_COMPONENT_TYPE : LB_COMPONENT_TYPE } ]

[#assign MOBILEAPP_COMPONENT_TYPE = "mobileapp"]

[#assign MOBILENOTIFIER_COMPONENT_TYPE = "mobilenotifier" ]
[#assign MOBILENOTIFIER_PLATFORM_COMPONENT_TYPE = "mobilenotifierplatform" ]

[#assign MTA_COMPONENT_TYPE = "mta"]
[#assign MTA_RULE_COMPONENT_TYPE = "mtarule" ]

[#assign NETWORK_ACL_COMPONENT_TYPE = "networkacl"]
[#assign NETWORK_COMPONENT_TYPE = "network" ]

[#assign NETWORK_GATEWAY_COMPONENT_TYPE = "gateway"]
[#assign NETWORK_GATEWAY_DESTINATION_COMPONENT_TYPE = "gatewaydestination"]

[#assign NETWORK_ROUTE_TABLE_COMPONENT_TYPE = "networkroute"]

[#assign NETWORK_ROUTER_COMPONENT_TYPE = "router"]
[#assign NETWORK_ROUTER_STATIC_ROUTE_COMPONENT_TYPE = "routerstaticroute" ]

[#assign OBJECTSQL_COMPONENT_TYPE = "objectsql"]

[#assign PRIVATE_SERVICE_COMPONENT_TYPE = "privateservice" ]

[#assign QUEUEHOST_COMPONENT_TYPE = "queuehost" ]

[#assign S3_COMPONENT_TYPE = "s3" ]

[#assign SECRETSTORE_COMPONENT_TYPE = "secretstore" ]
[#assign SECRETSTORE_SECRET_COMPONENT_TYPE = "secret" ]

[#assign SERVICE_REGISTRY_COMPONENT_TYPE = "serviceregistry" ]
[#assign SERVICE_REGISTRY_SERVICE_COMPONENT_TYPE = "serviceregistryservice" ]

[#assign SPA_COMPONENT_TYPE = "spa"]

[#assign SQS_COMPONENT_TYPE = "sqs"]

[#assign SUBSCRIPTION_COMPONENT_TYPE = "subscription"]

[#assign TEMPLATE_COMPONENT_TYPE = "template"]

[#assign TOPIC_COMPONENT_TYPE = "topic"]
[#assign TOPIC_SUBSCRIPTION_COMPONENT_TYPE = "topicsubscription" ]

[#assign USER_COMPONENT_TYPE = "user" ]

[#assign USERPOOL_COMPONENT_TYPE = "userpool"]
[#assign USERPOOL_CLIENT_COMPONENT_TYPE = "userpoolclient" ]
[#assign USERPOOL_AUTHPROVIDER_COMPONENT_TYPE = "userpoolauthprovider" ]
[#assign USERPOOL_RESOURCE_COMPONENT_TYPE = "userpoolresource" ]

[#assign DNS_ZONE_COMPONENT_TYPE = "dnszone"]

[#assign
    logWatcherChildrenConfiguration = [
        {
            "Names" : "LogFilter",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Links",
            "SubObjects": true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        }
    ]
]

[#assign logMetricChildrenConfiguration = [
        {
            "Names" : "LogFilter",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        }
    ]
]

[#assign scalingPolicyChildrenConfiguration =
    [
        {
            "Names" : "Type",
            "Types" : STRING_TYPE,
            "Values" : [ "Stepped", "Tracked", "Scheduled" ],
            "Default" : "Stepped"
        },
        {
            "Names" : "Cooldown",
            "Description" : "Cooldown time ( seconds ) after a scaling event has occurred before another event can be triggered",
            "Children" : [
                {
                    "Names" : "ScaleIn",
                    "Types" : NUMBER_TYPE,
                    "Default" : 300
                },
                {
                    "Names" : "ScaleOut",
                    "Types" : NUMBER_TYPE,
                    "Default" : 600
                }
            ]
        },
        {
            "Names" : "TrackingResource",
            "Description" : "The resource metric used to trigger scaling",
            "Children" : [
                {
                    "Names" : "Link",
                    "AttributeSet" : LINK_ATTRIBUTESET_TYPE
                },
                {
                    "Names" : "MetricTrigger",
                    "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
                }
            ]
        },
        {
            "Names" : "Stepped",
            "Children" : [
                {
                    "Names" : "MetricAggregation",
                    "Description" : "The method used to agregate the cloudwatch metric",
                    "Types" : STRING_TYPE,
                    "Values" : [ "Average", "Minimum", "Maximum" ],
                    "Default" : "Average"
                },
                {
                    "Names" : "CapacityAdjustment",
                    "Description" : "How to scale when the policy is triggered",
                    "Types" : STRING_TYPE,
                    "Values" : [ "Change", "Exact", "Percentage" ],
                    "Default" : "Change"
                },
                {
                    "Names" : "MinAdjustment",
                    "Description" : "When minimum scale adjustment value to apply when triggered",
                    "Types" : NUMBER_TYPE,
                    "Default" : -1
                },
                {
                    "Names" : "Adjustments",
                    "Description" : "The adjustments to apply at each step",
                    "SubObjects" : true,
                    "Children" : [
                        {
                            "Names" : "LowerBound",
                            "Description" : "The lower bound for the difference between the alarm threshold and the metric",
                            "Types" : NUMBER_TYPE
                        },
                        {
                            "Names" : "UpperBound",
                            "Description" : "The upper bound for the difference between the alarm threshold and the metric",
                            "Types" : NUMBER_TYPE
                        },
                        {
                            "Names" : "AdjustmentValue",
                            "Description" : "The value to apply when the adjustment step is triggered",
                            "Types" : NUMBER_TYPE,
                            "Default" : 1
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "Tracked",
            "Children" : [
                {
                    "Names" : "TargetValue",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "ScaleInEnabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "RecommendedMetric",
                    "Description" : "Use a recommended (predefined) metric for scaling",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "Scheduled",
            "Children" : [
                {
                    "Names" : "ProcessorProfile",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Schedule",
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]
]

[#assign lbChildConfiguration = [
        {
            "Names" : "Tier",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LinkName",
            "Types" : STRING_TYPE,
            "Default" : "lb"
        },
        {
            "Names" : "Instance",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Types" : STRING_TYPE
        },
        {
            "Names" : ["PortMapping", "Port"],
            "Types" : STRING_TYPE,
            "Default" : ""
        }
    ]
]

[#assign srvRegChildConfiguration = [
        {
            "Names" : "Tier",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Component",
            "Types" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "LinkName",
            "Types" : STRING_TYPE,
            "Default" : "srvreg"
        },
        {
            "Names" : "Instance",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "Version",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "RegistryService",
            "Types" : STRING_TYPE
        }
    ]
]

[#assign wafChildConfiguration = [
        {
            "Names" : "Version",
            "Description" : "Version of WAF to use",
            "Types"  : STRING_TYPE,
            "Values" : [ "V1","V2"],
            "Default" : "V1"
        },
        {
            "Names" : "IPAddressGroups",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "CountryGroups",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : []
        },
        {
            "Names" : "OWASP",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "Logging",
            "Children" : [
                {
                    "Names" : "Enabled",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                }
            ]
        },
        {
            "Names" : "Profiles",
            "Children" : [
                {
                    "Names" : "Logging",
                    "Description" : "Logging profile to process WAF Logs that are stored in the OpsData DataBucket.",
                    "Types"  : STRING_TYPE,
                    "Default" : "waf"
                }
            ]
        },
        {
            "Names" : "RateLimits",
            "SubObjects" : true,
            "Children" : [
                {
                    "Names" : "IPAddressGroups",
                    "Types" : ARRAY_OF_STRING_TYPE,
                    "Default" : []
                },
                {
                    "Names" : "Limit",
                    "Types" : NUMBER_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    ]
]

[#assign settingsChildConfiguration = [
        {
            "Names" : "AsFile",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "FileFormat",
            "Types" : STRING_TYPE,
            "Description" : "The format of the file when using AsFile",
            "Values" : [ "json", "yaml" ],
            "Default" : "json"
        },
        {
            "Names" : "Json",
            "Children" : [
                {
                    "Names" : "Escaped",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Prefix",
                    "Types" : STRING_TYPE,
                    "Values" : ["json", ""],
                    "Default" : "json"
                }
            ]
        }
    ]
]

[#assign autoScalingChildConfiguration = [
    {
        "Names" : "DetailedMetrics",
        "Types" : BOOLEAN_TYPE,
        "Default" : true,
        "Description" : "Enable the collection of autoscale group detailed metrics"
    },
    {
        "Names" : "MinUpdateInstances",
        "Types" : NUMBER_TYPE,
        "Default" : 1,
        "Description" : "The minimum number of instances which must be available during an update"
    },
    {
        "Names" : "MinSuccessInstances",
        "Types" : NUMBER_TYPE,
        "Description" : "The minimum percantage of instances that must sucessfully update",
        "Default" : 75
    },
    {
        "Names" : "ReplaceCluster",
        "Types" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "When set to true a brand new cluster will be built, if false the instances in the current cluster will be replaced"
    },
    {
        "Names" : "UpdatePauseTime",
        "Types" : STRING_TYPE,
        "Default" : "10M",
        "Description" : "How long to pause betweeen updates of instances"
    },
    {
        "Names" : "StartupTimeout",
        "Types" : STRING_TYPE,
        "Default" : "15M",
        "Description" : "How long to wait for a cfn-signal to be received from a host"
    },
    {
        "Names" : "AlwaysReplaceOnUpdate",
        "Types" : BOOLEAN_TYPE,
        "Default" : false,
        "Description" : "Replace instances on every update action"
    },
    {
        "Names" : "ActivityCooldown",
        "Types" : NUMBER_TYPE,
        "Default" : 30
    }
]]

[#assign domainChildConfiguration = [
    {
        "Names" : "Name",
        "Description" : "The name of the domain",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Stem",
        "Description" : "The root stem domain name that children will be based on",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Zone",
        "Description" : "The zone the endpoint belongs to",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Bare",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Role",
        "Types" : STRING_TYPE,
        "Values" : [DOMAIN_ROLE_PRIMARY, DOMAIN_ROLE_SECONDARY]
    },
    "InhibitEnabled"
]]

[#assign domainNameChildConfiguration = [
    {
        "Names" : "Domain",
        "Description" : "Explicit domain id which will override the product domain",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "IncludeInDomain",
        "Children" : [
            {
                "Names" : "Product",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Types" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign hostNameChildConfiguration = [
    {
        "Names" : "Host",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "HostParts",
        "Types" : ARRAY_OF_STRING_TYPE
    },
    {
        "Names" : "IncludeInHost",
        "Children" : [
            {
                "Names" : "Product",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Environment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Segment",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Tier",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Component",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Instance",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Version",
                "Types" : BOOLEAN_TYPE
            },
            {
                "Names" : "Host",
                "Types" : BOOLEAN_TYPE
            }
        ]
    }
]]

[#assign certificateChildConfiguration =
    domainNameChildConfiguration +
    hostNameChildConfiguration +
    [
        {
            "Names" : "External",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Types" : BOOLEAN_TYPE
        }
    ]
]

[#assign s3NotificationChildConfiguration = [
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Prefix",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Suffix",
        "Types" : STRING_TYPE
    },
    {
        "Names" : "Events",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : [ "create" ],
        "Values" : [ "create", "delete", "restore", "reducedredundancy" ]
    },
    {
        "Names" : "aws:QueuePermissionMigration",
        "Description" : "Deprecation alert: set to true once policy updated for queue",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "aws:TopicPermissionMigration",
        "Description" : "Deprecation alert: set to true once policy updated for topic",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    }
]]

[#assign s3EncryptionChildConfiguration = [
    {
        "Names" : "Enabled",
        "Description" : "Enable at rest encryption",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "EncryptionSource",
        "Types" : STRING_TYPE,
        "Description" : "The encryption service to use - LocalService = S3, EncryptionService = native encryption service (kms)",
        "Values" : [ "EncryptionService", "LocalService" ],
        "Default" : "EncryptionService"
    }
]]

[#assign dynamoDbTableChildConfiguration = [
    {
        "Names" : "Billing",
        "Description" : "The billing mode for the table",
        "Types"  : STRING_TYPE,
        "Values" : [ "provisioned", "per-request" ],
        "Default" : "provisioned"
    },
    {
        "Names" : "Encrypted",
        "Description" : "Enable at rest encryption",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Capacity",
        "Children" : [
            {
                "Names" : "Read",
                "Description" : "When using provisioned billing the maximum RCU of the table",
                "Types" : NUMBER_TYPE,
                "Default" : 1
            },
            {
                "Names" : "Write",
                "Description" : "When using provisioned billing the maximum WCU of the table",
                "Types" : NUMBER_TYPE,
                "Default" : 1
            }
        ]
    },
    {
        "Names" : "Backup",
        "Children" : [
            {
                "Names" : "Enabled",
                "Description" : "Enables point in time recovery on the table",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
    },
    {
        "Names" : "Stream",
        "Children" : [
            {
                "Names" : "Enabled",
                "Description" : "Enables dynamodb event stream",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "ViewType",
                "Types" : STRING_TYPE,
                "Values" : [ "KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES" ],
                "Default" : "NEW_IMAGE"
            }
        ]
    }
]]


[#assign secretTemplateConfiguration = [
    {
        "Names" : "Generated",
        "Children" : [
            {
                "Names" : "Content",
                "Description" : "A JSON object which contains the nonsensitve parts of the secret",
                "Types" : OBJECT_TYPE,
                "Default" : {
                    "username" : "admin"
                }
            },
            {
                "Names" : "SecretKey",
                "Description" : "The key in the JSON secret to set the generated secret to",
                "Types" : STRING_TYPE,
                "Default" : "password"
            }
        ]
    }
]]

[#assign secretRotationConfiguration = [
    {
        "Names" : "Lifecycle",
        "Description" : "The lifecycle for a given Secret.",
        "Children" : [
            {
                "Names" : "Rotation",
                "Description" : "The Secret rotation schedule, in number of days - accepts rate() or cron() formats.",
                "Children" : [
                    {
                        "Names" : "Enabled",
                        "Description" : "Enable Secret rotation.",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            }
        ]
    }
]]

[#assign secretConfiguration = [
    {
        "Names" : "Source",
        "Types" : STRING_TYPE,
        "Values" : [ "user", "generated" ],
        "Default" : "user"
    },
    {
        "Names" : "Requirements",
        "Description" : "Format requirements for the Secret",
        "AttributeSet" : SECRETSTRING_ATTRIBUTESET_TYPE
    }
]]

[#assign networkRuleChildConfiguration = [
    {
        "Names" : "Ports",
        "Description" : "A list of port ids from the Ports reference",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "IPAddressGroups",
        "Description" : "A list of IP Address groups ids from the IPAddressGroups reference",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "SecurityGroups",
        "Description" : "A list of security groups or ids - for internal use only",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "Description",
        "Description" : "A description that will be applied to the rule",
        "Types" : STRING_TYPE,
        "Default" : ""
    }
]]

[#assign containerHostAttributes = [
    {
        "Names" : [ "Extensions", "Fragment", "Container" ],
        "Description" : "Extensions to invoke as part of component processing",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Default" : []
    },
    {
        "Names" : "FixedIP",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "LogDriver",
        "Types" : STRING_TYPE,
        "Values" : ["awslogs", "json-file", "fluentd"],
        "Default" : "awslogs"
    },
    {
        "Names" : "VolumeDrivers",
        "Types" : ARRAY_OF_STRING_TYPE,
        "Values" : [ "ebs" ],
        "Default" : []
    },
    {
        "Names" : "ClusterLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "ComputeProvider",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Storage",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Description" : "profile to define where logs are forwarded to from this component",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "LogFile",
                    "Description" : "Defines the logfile profile which sets the log files to collect from the compute instance",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Bootstrap",
                    "Description" : "A profile to include additional bootstrap sources as part of the instance startup",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            }
        ]
    },
    {
        "Names" : "AutoScaling",
        "Children" : autoScalingChildConfiguration
    },
    {
        "Names" : "HostScalingPolicies",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "Type",
                "Types" : STRING_TYPE,
                "Values" : [ "Stepped", "Tracked", "Scheduled", "ComputeProvider" ],
                "Default" : "ComputeProvider"
            },
            {
                "Names" : "ComputeProvider",
                "Children": [
                    {
                        "Names" : "MinAdjustment",
                        "Description" : "The minimum instances to update during scaling activities",
                        "Types" : NUMBER_TYPE,
                        "Default" : 1
                    },
                    {
                        "Names" : "MaxAdjustment",
                        "Description" : "The maximum instances to  update during scaling activities",
                        "Types" : NUMBER_TYPE,
                        "Default" : 10000
                    },
                    {
                        "Names" : "TargetCapacity",
                        "Description" : "The target usage of the autoscale group to maintain as a percentage",
                        "Types" : NUMBER_TYPE,
                        "Default" : 90
                    },
                    {
                        "Names" : "ManageTermination",
                        "Description" : "Alow the computer provider to manage when instances will be terminated",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    }
                ] + scalingPolicyChildrenConfiguration
            }
        ]
    },
    {
        "Names" : "DockerUsers",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "UserName",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "UID",
                "Types" : NUMBER_TYPE,
                "Mandatory" : true
            }
        ]
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "Hibernate",
        "Children" : [
            {
                "Names" : "Enabled",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "StartUpMode",
                "Types" : STRING_TYPE,
                "Values" : ["replace"],
                "Default" : "replace"
            }
        ]
    },
    {
        "Names" : "Role",
        "Types" : STRING_TYPE,
        "Description" : "Server configuration role",
        "Default" : ""
    },
    {
        "Names" : "ComputeInstance",
        "Description" : "Configuration of compute instances used in the component",
        "Children" : [
            {
                "Names" : "ManagementPorts",
                "Description" : "The network ports used for remote management of the instance",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "ssh" ]
            },
            {
                "Names" : "Image",
                "Description" : "Configures the source of the virtual machine image used for the instance",
                "AttributeSet" : ECS_COMPUTEIMAGE_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "OperatingSystem",
                "Description" : "The operating system details of the compute instance",
                "AttributeSet" : OPERATINGSYSTEM_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "OSPatching",
                "Description" : "Configuration for scheduled OS Patching",
                "AttributeSet" : OSPATCHING_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "ComputeTasks",
                "Description" : "Customisation to setup the compute instance from its image",
                "Children" : [
                    {
                        "Names" : "Extensions",
                        "Description" : "A list of extensions to source boostrap tasks from",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "UserTasksRequired",
                        "Description" : "A list of compute task types which must be accounted for in extensions on top of the component tasks",
                        "Types" : ARRAY_OF_STRING_TYPE,
                        "Default" : []
                    }
                ]
            }
        ]
    }
]]

[#assign containerServiceAttributes = [
    {
        "Names" : "Engine",
        "Description" : "The engine used to run the container",
        "Types" : STRING_TYPE,
        "Values" : [ "ec2" ],
        "Default" : "ec2"
    },
    {
        "Names" : "Containers",
        "SubObjects" : true,
        "AttributeSet" : CONTTAINERTASK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "DesiredCount",
        "Types" : NUMBER_TYPE
    },
    {
        "Names" : "ScalingPolicies",
        "SubObjects" : true,
        "Children" : scalingPolicyChildrenConfiguration
    },
    {
        "Names" : "UseTaskRole",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "NetworkMode",
        "Types" : STRING_TYPE,
        "Values" : ["none", "bridge", "host"],
        "Default" : ""
    },
    {
        "Names" : "ContainerNetworkLinks",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Placement",
        "Children" : [
            {
                "Names" : "Strategy",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Values" : [
                    "spread-multiAZ",
                    "spread-instance",
                    "binpack-cpu",
                    "binpack-memory",
                    "daemon",
                    "random"
                ],
                "Description" : "How to place containers on the cluster",
                "Default" : []
            },
            {
                "Names" : "DistinctInstance",
                "Types" : BOOLEAN_TYPE,
                "Description" : "Each task is running on a different container instance when true",
                "Default" : true
            },
            {
                "Names" : "ComputeProvider",
                "Description" : "The compute provider placement policy",
                "Children" : [
                    {
                        "Names" : "Default",
                        "Children" : [
                            {
                                "Names" : "Provider",
                                "Description" : "The default container compute provider - _engine uses the default provider of the engine",
                                "Types"  : STRING_TYPE,
                                "Values" : [ "_engine" ],
                                "Default" : "_engine"
                            },
                            {
                                "Names" : "Weight",
                                "Types" : NUMBER_TYPE,
                                "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                "Default" : 1
                            },
                            {
                                "Names" : "RequiredCount",
                                "Description" : "The minimum count of containers to run on the default provider",
                                "Types" : NUMBER_TYPE,
                                "Default" : 1
                            }
                        ]
                    },
                    {
                        "Names" : "Additional",
                        "Description" : "Providers who will meet the additional compute capacity outside of the default",
                        "SubObjects" : true,
                        "Children" : [
                            {
                                "Names" : "Provider",
                                "Types" : STRING_TYPE,
                                "Values" : [ "_engine" ],
                                "Mandatory" : true
                            },
                            {
                                "Names" : "Weight",
                                "Types" : NUMBER_TYPE,
                                "Description" : "The ratio of containers allocated to the provider based on the configured providers",
                                "Default" : 1
                            }
                        ]
                    }
                ]
            }
        ]
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Processor",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    }
]]

[#assign containerTaskAttributes = [
    {
        "Names" : "Engine",
        "Description" : "The engine used to run the container",
        "Types" : STRING_TYPE,
        "Values" : [ "ec2" ],
        "Default" : "ec2"
    },
    {
        "Names" : "Containers",
        "SubObjects" : true,
        "AttributeSet" : CONTTAINERTASK_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "UseTaskRole",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "Permissions",
        "Children" : [
            {
                "Names" : "Decrypt",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AsFile",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppData",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "AppPublic",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            }
        ]
    },
    {
        "Names" : "TaskLogGroup",
        "Types" : BOOLEAN_TYPE,
        "Default" : true
    },
    {
        "Names" : "LogMetrics",
        "SubObjects" : true,
        "Children" : logMetricChildrenConfiguration
    },
    {
        "Names" : "Alerts",
        "SubObjects" : true,
        "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
    },
    {
        "Names" : "NetworkMode",
        "Types" : STRING_TYPE,
        "Values" : ["none", "bridge", "host"],
        "Default" : ""
    },
    {
        "Names" : "FixedName",
        "Types" : BOOLEAN_TYPE,
        "Default" : false
    },
    {
        "Names" : "Schedules",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "Expression",
                "Types" : STRING_TYPE,
                "Default" : "rate(1 hours)"
            },
            {
                "Names" : "TaskCount",
                "Description" : "The number of tasks to run on the schedule",
                "Types" : NUMBER_TYPE,
                "Default" : 1
            }
        ]
    },
    {
        "Names" : "Profiles",
        "Children" :
            [
                {
                    "Names" : "Alert",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Network",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                },
                {
                    "Names" : "Logging",
                    "Types" : STRING_TYPE,
                    "Default" : "default"
                }
            ]
    },
    {
        "Names" : "Links",
        "SubObjects": true,
        "AttributeSet" : LINK_ATTRIBUTESET_TYPE
    }
]]

[#-- Not for general use - framework only --]
[#assign coreProfileChildConfiguration = [
    {
        "Names" : ["Profiles"],
        "Children" : [
            {
                "Names" : "Deployment",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Policy",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Placement",
                "Types" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Baseline",
                "Description" : "The profile used to lookup standard services provided by the segment baseline",
                "Types" : STRING_TYPE,
                "Default" : "default"
            },
            {
                "Names" : "Testing",
                "Description" : "The testing profiles to apply to the component",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            }
        ]
    }
] ]

[#assign coreSettingsNamespacesConfiguration = [
    {
        "Names" : [ "SettingNamespaces" ],
        "Description" : "Additional namespaces to use during settings lookups",
        "SubObjects" : true,
        "Children" : [
            {
                "Names" : "Match",
                "Description" : "How to match the namespace with available settings",
                "Types" : STRING_TYPE,
                "Values" : [ "exact", "partial" ],
                "Default" : "exact"
            },
            {
                "Names" : "Order",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [
                    "Tier",
                    "Component",
                    "Type",
                    "SubComponent",
                    "Instance",
                    "Version",
                    "Name"
                ]
            },
            {
                "Names" : "IncludeInNamespace",
                "Children" : [
                    {
                        "Names" : "Tier",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Component",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Type",
                        "Types"  : BOOLEAN_TYPE,
                        "Default" : false
                    }
                    {
                        "Names" : "SubComponent",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "Instance",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Version",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : true
                    },
                    {
                        "Names" : "Name",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            },
            {
                "Names" : "Name",
                "Types" : STRING_TYPE,
                "Default" : ""
            }
        ]
    }
]]

[#assign tracingChildConfiguration =
    [
        {
            "Names" : "Mode",
            "Types" : STRING_TYPE,
            "Values" : ["active", "passthrough"]
        }
    ]
]
